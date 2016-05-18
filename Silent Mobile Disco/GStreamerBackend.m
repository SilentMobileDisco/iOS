#import "GStreamerBackend.h"

#include <gst/gst.h>
#include <gst/video/video.h>
#include <string.h>
#include <math.h>
#include <gst/net/gstnet.h>



GST_DEBUG_CATEGORY_STATIC (debug_category);
#define GST_CAT_DEFAULT debug_category

/* Do not allow seeks to be performed closer than this distance. It is visually useless, and will probably
 * confuse some demuxers. */
#define SEEK_MIN_DELAY (500 * GST_MSECOND)
#define AUDIO_CAPS "application/x-rtp,media=(string)audio,clock-rate=(int)8000,encoding-name=(string)PCMA"

#define AUDIO_DEPAY "rtppcmadepay"
#define AUDIO_DEC   "alawdec"
#define AUDIO_SINK  "autoaudiosink"

/* the destination machine to send RTCP to. This is the address of the sender and
 * is used to send back the RTCP reports of this receiver. If the data is sent
 * from another machine, change this address. */
#define DEST_HOST "127.0.0.1"
#define PLAYBACK_DELAY_MS 40

#define MULTICAST_ADDR "239.255.42.99"

@interface GStreamerBackend()
-(void)setUIMessage:(gchar*) message;
-(void)app_function;
-(void)check_initialization_complete;

@end

@implementation GStreamerBackend {
    id ui_delegate;              /* Class that we use to interact with the user interface */
    GstElement *pipeline;        /* The running pipeline */
    GstElement *video_sink;      /* The video sink element which receives XOverlay commands */
    GMainContext *context;       /* GLib context used to run the main loop */
    GMainLoop *main_loop;        /* GLib main loop */
    gboolean initialized;        /* To avoid informing the UI multiple times about the initialization */
    GstState state;              /* Current pipeline state */
    GstState target_state;       /* Desired pipeline state, to be set once buffering is complete */
    gint64 duration;             /* Cached clip duration */
    gint64 desired_position;     /* Position to seek to, once the pipeline is running */
    GstClockTime last_seek_time; /* For seeking overflow prevention (throttling) */
    gboolean is_live;            /* Live streams do not use buffering */
    NSString *capsString;
}

/*
 * Interface methods
 */

-(id) init:(id) uiDelegate ip:(NSString *)ip caps:(NSString *)caps
{
    if (self = [super init])
    {
        self->ui_delegate = uiDelegate;
        self->duration = GST_CLOCK_TIME_NONE;
        self.ip = ip;
        self->capsString = caps;
        
        GST_DEBUG_CATEGORY_INIT (debug_category, "tutorial-4", 0, "iOS tutorial 4");
        gst_debug_set_threshold_for_name("tutorial-4", GST_LEVEL_DEBUG);

        /* Start the bus monitoring task */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self app_function];
        });
    }

    return self;
}

-(void) deinit
{
    if (main_loop) {
        g_main_loop_quit(main_loop);
    }
}

-(void) play
{
    target_state = GST_STATE_PLAYING;
    is_live = (gst_element_set_state (pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_NO_PREROLL);
}

-(void) pause
{
    target_state = GST_STATE_PAUSED;
    is_live = (gst_element_set_state (pipeline, GST_STATE_PAUSED) == GST_STATE_CHANGE_NO_PREROLL);
}

-(void) setUri:(NSString*)uri
{
    const char *char_uri = [uri UTF8String];
    g_object_set(pipeline, "uri", char_uri, NULL);
    GST_DEBUG ("URI set to %s", char_uri);
}


/*
 * Private methods
 */

/* Change the message on the UI through the UI delegate */
-(void)setUIMessage:(gchar*) message
{
    NSString *string = [NSString stringWithUTF8String:message];
    if(ui_delegate && [ui_delegate respondsToSelector:@selector(gstreamerSetUIMessage:)])
    {
        [ui_delegate gstreamerSetUIMessage:string];
    }
}

/* Tell the application what is the current position and clip duration */
-(void) setCurrentUIPosition:(gint)pos duration:(gint)dur
{
    if(ui_delegate && [ui_delegate respondsToSelector:@selector(setCurrentPosition:duration:)])
    {
        [ui_delegate setCurrentPosition:pos duration:dur];
    }
}


/* Retrieve errors from the bus and show them on the UI */
static void error_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self)
{
    GError *err;
    gchar *debug_info;
    gchar *message_string;
    
    gst_message_parse_error (msg, &err, &debug_info);
    message_string = g_strdup_printf ("Error received from element %s: %s", GST_OBJECT_NAME (msg->src), err->message);
    g_clear_error (&err);
    g_free (debug_info);
    [self setUIMessage:message_string];
    g_free (message_string);
    gst_element_set_state (self->pipeline, GST_STATE_NULL);
}

/* Called when the End Of the Stream is reached. Just move to the beginning of the media and pause. */
static void eos_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self) {
    self->target_state = GST_STATE_PAUSED;
    self->is_live = (gst_element_set_state (self->pipeline, GST_STATE_PAUSED) == GST_STATE_CHANGE_NO_PREROLL);
}

/* Called when the duration of the media changes. Just mark it as unknown, so we re-query it in the next UI refresh. */
static void duration_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self) {
    self->duration = GST_CLOCK_TIME_NONE;
}

/* Called when buffering messages are received. We inform the UI about the current buffering level and
 * keep the pipeline paused until 100% buffering is reached. At that point, set the desired state. */
static void buffering_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self) {
    gint percent;

    if (self->is_live)
        return;

    gst_message_parse_buffering (msg, &percent);
    if (percent < 100 && self->target_state >= GST_STATE_PAUSED) {
        gchar * message_string = g_strdup_printf ("Buffering %d%%", percent);
        gst_element_set_state (self->pipeline, GST_STATE_PAUSED);
        [self setUIMessage:message_string];
        g_free (message_string);
    } else if (self->target_state >= GST_STATE_PLAYING) {
        gst_element_set_state (self->pipeline, GST_STATE_PLAYING);
    } else if (self->target_state >= GST_STATE_PAUSED) {
        [self setUIMessage:"Buffering complete"];
    }
}

/* Called when the clock is lost */
static void clock_lost_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self) {
    gchar *message = g_strdup_printf("Clock lost!");
    [self setUIMessage:message];
    if (self->target_state >= GST_STATE_PLAYING) {
        gst_element_set_state (self->pipeline, GST_STATE_PAUSED);
        gst_element_set_state (self->pipeline, GST_STATE_PLAYING);
        gchar *message = g_strdup_printf("Clock lost!");
        [self setUIMessage:message];

    }
}
/* Notify UI about pipeline state changes */
static void state_changed_cb (GstBus *bus, GstMessage *msg, GStreamerBackend *self)
{
    GstState old_state, new_state, pending_state;
    gst_message_parse_state_changed (msg, &old_state, &new_state, &pending_state);
    /* Only pay attention to messages coming from the pipeline, not its children */
    if (GST_MESSAGE_SRC (msg) == GST_OBJECT (self->pipeline)) {
        self->state = new_state;
        gchar *message = g_strdup_printf("State changed to %s", gst_element_state_get_name(new_state));
        [self setUIMessage:message];
        g_free (message);
        
        if (old_state == GST_STATE_READY && new_state == GST_STATE_PAUSED)
        {
        }
    }
}


/* Check if all conditions are met to report GStreamer as initialized.
 * These conditions will change depending on the application */
-(void) check_initialization_complete
{
    if (!initialized && main_loop) {
        GST_DEBUG ("Initialization complete, notifying application.");
        if (ui_delegate && [ui_delegate respondsToSelector:@selector(gstreamerInitialized)])
        {
            [ui_delegate gstreamerInitialized];
        }
        initialized = TRUE;
    }
}

/* print the stats of a source */
static void
print_source_stats (GObject * source)
{
    GstStructure *stats;
    gchar *str;
    
    g_return_if_fail (source != NULL);
    
    /* get the source stats */
    g_object_get (source, "stats", &stats, NULL);
    
    /* simply dump the stats structure */
    str = gst_structure_to_string (stats);
    g_print ("source stats: %s\n", str);
    
    gst_structure_free (stats);
    g_free (str);
}

/* will be called when rtpbin signals on-ssrc-active. It means that an RTCP
 * packet was received from another source. */
static void
on_ssrc_active_cb (GstElement * rtpbin, guint sessid, guint ssrc,
                   GstElement * depay)
{
    GObject *session, *isrc, *osrc;
    
    g_print ("got RTCP from session %u, SSRC %u\n", sessid, ssrc);
    
    /* get the right session */
    g_signal_emit_by_name (rtpbin, "get-internal-session", sessid, &session);
    
    /* get the internal source (the SSRC allocated to us, the receiver */
    g_object_get (session, "internal-source", &isrc, NULL);
    print_source_stats (isrc);
    
    /* get the remote source that sent us RTCP */
    g_signal_emit_by_name (session, "get-source-by-ssrc", ssrc, &osrc);
    print_source_stats (osrc);
}

/* will be called when rtpbin has validated a payload that we can depayload */
static void
pad_added_cb (GstElement * rtpbin, GstPad * new_pad, GstElement * depay)
{
    GstPad *sinkpad;
    GstPadLinkReturn lres;
    
    g_print ("new payload on pad: %s\n", GST_PAD_NAME (new_pad));
    
    sinkpad = gst_element_get_static_pad (depay, "sink");
    g_assert (sinkpad);
    
    lres = gst_pad_link (new_pad, sinkpad);
    g_assert (lres == GST_PAD_LINK_OK);
    gst_object_unref (sinkpad);
}

/* Main method for the bus monitoring code */
-(void) app_function
{
    GstElement *rtpbin, *rtpsrc, *rtcpsrc, *rtcpsink;
    GstElement *audiodepay, *audiodec, *audiores, *audioconv, *audiosink;
    GstElement *buffer;

        GSource *bus_source;

    GstCaps *caps;
    gboolean res;
    GstPadLinkReturn lres;
    GstPad *srcpad, *sinkpad;
        GstBus *bus;

    GstClock *net_clock;
    
    net_clock = gst_net_client_clock_new ("net_clock", [self.ip UTF8String], 8554, 0);
    if (net_clock == NULL) {
        g_print ("Failed to create net clock client");
        return;
    }
    
    g_print("Waiting for network clock to synchronize");
    /* Wait for the clock to stabilise */
    gst_clock_wait_for_sync (net_clock, GST_CLOCK_TIME_NONE);
    g_print("Clock synchronized!");
    
    /* the pipeline to hold everything */
    pipeline = gst_pipeline_new (NULL);
    g_assert (pipeline);
    
    gst_pipeline_use_clock (GST_PIPELINE (pipeline), net_clock);
    
    
    /* the udp src and source we will use for RTP and RTCP */
    rtpsrc = gst_element_factory_make ("udpsrc", "rtpsrc");
    g_assert (rtpsrc);
    g_object_set (rtpsrc, "port", 5002, NULL);
    /* we need to set caps on the udpsrc for the RTP data */
    caps = gst_caps_from_string ([self->capsString UTF8String]);
    g_object_set (rtpsrc, "caps", caps, NULL);
    
    /* Multicast flags */
    g_object_set (rtpsrc, "address", MULTICAST_ADDR, NULL);
    g_object_set (rtpsrc, "auto-multicast", TRUE, NULL);
    
    gst_caps_unref (caps);
    
    /* Jitter buffer - it seems like while some networks don't need an additional jitter buffer here, some break without it.*/
    buffer = gst_element_factory_make ("rtpjitterbuffer", "buffer");
    g_assert(buffer);
    g_object_set(buffer, "latency", PLAYBACK_DELAY_MS, NULL);
    
    rtcpsrc = gst_element_factory_make ("udpsrc", "rtcpsrc");
    g_assert (rtcpsrc);
    g_object_set (rtcpsrc, "port", 5003, NULL);
    
    rtcpsink = gst_element_factory_make ("udpsink", "rtcpsink");
    g_assert (rtcpsink);
    g_object_set (rtcpsink, "port", 5007, "host", DEST_HOST, NULL);
    /* no need for synchronisation or preroll on the RTCP sink */
    g_object_set (rtcpsink, "async", FALSE, "sync", FALSE, NULL);
    
    gst_bin_add_many (GST_BIN (pipeline), rtpsrc, rtcpsrc, rtcpsink, NULL);
    
    /* the depayloading and decoding */
    audiodepay = gst_element_factory_make (AUDIO_DEPAY, "audiodepay");
    g_assert (audiodepay);
    audiodec = gst_element_factory_make (AUDIO_DEC, "audiodec");
    g_assert (audiodec);
    /* the audio playback and format conversion */
    audioconv = gst_element_factory_make ("audioconvert", "audioconv");
    g_assert (audioconv);
    audiores = gst_element_factory_make ("audioresample", "audiores");
    g_assert (audiores);
    audiosink = gst_element_factory_make (AUDIO_SINK, "audiosink");
    g_assert (audiosink);
    
    /* add depayloading and playback to the pipeline and link */
    gst_bin_add_many (GST_BIN (pipeline), audiodepay, audiodec, audioconv,
                      audiores, audiosink, NULL);
    
    res = gst_element_link_many (audiodepay, audiodec, audioconv, audiores,
                                 audiosink, NULL);
    g_assert (res == TRUE);
    
    /* the rtpbin element */
    rtpbin = gst_element_factory_make ("rtpbin", "rtpbin");
    g_object_set (rtpbin, "latency", PLAYBACK_DELAY_MS,
                  "ntp-time-source", 3, "buffer-mode", 4, "ntp-sync", TRUE, NULL);
    
    g_assert (rtpbin);
    
    gst_bin_add (GST_BIN (pipeline), rtpbin);
    gst_bin_add (GST_BIN (pipeline), buffer);
    
    // First: link rtpsrc to the buffer. Then link the buffer to the rtpbin
    
    srcpad = gst_element_get_static_pad (rtpsrc, "src");
    sinkpad = gst_element_get_static_pad (buffer, "sink");
    lres = gst_pad_link (srcpad, sinkpad);
    g_assert (lres == GST_PAD_LINK_OK);
    gst_object_unref (srcpad);
    gst_object_unref (sinkpad);
    
    
    srcpad = gst_element_get_static_pad (buffer, "src");
    sinkpad = gst_element_get_request_pad (rtpbin, "recv_rtp_sink_0");
    lres = gst_pad_link (srcpad, sinkpad);
    g_assert (lres == GST_PAD_LINK_OK);
    gst_object_unref (srcpad);
    
    /* get an RTCP sinkpad in session 0 */
    srcpad = gst_element_get_static_pad (rtcpsrc, "src");
    sinkpad = gst_element_get_request_pad (rtpbin, "recv_rtcp_sink_0");
    lres = gst_pad_link (srcpad, sinkpad);
    g_assert (lres == GST_PAD_LINK_OK);
    gst_object_unref (srcpad);
    gst_object_unref (sinkpad);
    
    /* get an RTCP srcpad for sending RTCP back to the sender */
    srcpad = gst_element_get_request_pad (rtpbin, "send_rtcp_src_0");
    sinkpad = gst_element_get_static_pad (rtcpsink, "sink");
    lres = gst_pad_link (srcpad, sinkpad);
    g_assert (lres == GST_PAD_LINK_OK);
    gst_object_unref (sinkpad);
    
    /* the RTP pad that we have to connect to the depayloader will be created
     * dynamically so we connect to the pad-added signal, pass the depayloader as
     * user_data so that we can link to it. */
    g_signal_connect (rtpbin, "pad-added", G_CALLBACK (pad_added_cb), audiodepay);
    
    /* give some stats when we receive RTCP */
    g_signal_connect (rtpbin, "on-ssrc-active", G_CALLBACK (on_ssrc_active_cb),
                      audiodepay);
    
    /* set the pipeline to playing */
    g_print ("Readying pipeline\n");
    gst_element_set_state (pipeline, GST_STATE_READY);
    
    /* Attach to callbacks to display status to the user */
    bus = gst_element_get_bus (pipeline);
    bus_source = gst_bus_create_watch (bus);
    g_source_set_callback (bus_source, (GSourceFunc) gst_bus_async_signal_func, NULL, NULL);
    g_source_attach (bus_source, context);
    g_source_unref (bus_source);
    g_signal_connect (G_OBJECT (bus), "message::error", (GCallback)error_cb, (__bridge void *)self);
    g_signal_connect (G_OBJECT (bus), "message::eos", (GCallback)eos_cb, (__bridge void *)self);
    g_signal_connect (G_OBJECT (bus), "message::state-changed", (GCallback)state_changed_cb, (__bridge void *)self);
    g_signal_connect (G_OBJECT (bus), "message::clock-lost", (GCallback)clock_lost_cb, (__bridge void *)self);
    gst_object_unref (bus);

    /* we need to run a GLib main loop to get the messages */
    main_loop = g_main_loop_new (NULL, FALSE);
    [self check_initialization_complete];

    g_main_loop_run (main_loop);
    
    g_print ("stopping receiver pipeline\n");
    gst_element_set_state (pipeline, GST_STATE_NULL);
    
    gst_object_unref (pipeline);
    

}


//-(void) app_function_orig
//{
//    GstBus *bus;
//    GSource *timeout_source;
//    GSource *bus_source;
//    GError *error = NULL;
//
//    GST_DEBUG ("Creating pipeline");
//
//    /* Create our own GLib Main Context and make it the default one */
//    context = g_main_context_new ();
//    g_main_context_push_thread_default(context);
//    
//    /* Build pipeline */
//    pipeline = gst_parse_launch("playbin uri=rtsp://10.0.0.14:8554/test uridecodebin0::source::latency=50", &error);
//    if (error) {
//        gchar *message = g_strdup_printf("Unable to build pipeline: %s", error->message);
//        g_clear_error (&error);
//        [self setUIMessage:message];
//        g_free (message);
//        return;
//    }
//
//    /* Set the pipeline to READY, so it can already accept a window handle */
//    gst_element_set_state(pipeline, GST_STATE_READY);
//    
//    video_sink = gst_bin_get_by_interface(GST_BIN(pipeline), GST_TYPE_VIDEO_OVERLAY);
//    if (!video_sink) {
//        GST_ERROR ("Could not retrieve video sink");
//        return;
//    }
////    gst_video_overlay_set_window_handle(GST_VIDEO_OVERLAY(video_sink), (guintptr) (id) ui_video_view);
//
//    /* Instruct the bus to emit signals for each received message, and connect to the interesting signals */
//    bus = gst_element_get_bus (pipeline);
//    bus_source = gst_bus_create_watch (bus);
//    g_source_set_callback (bus_source, (GSourceFunc) gst_bus_async_signal_func, NULL, NULL);
//    g_source_attach (bus_source, context);
//    g_source_unref (bus_source);
//    g_signal_connect (G_OBJECT (bus), "message::error", (GCallback)error_cb, (__bridge void *)self);
//    g_signal_connect (G_OBJECT (bus), "message::eos", (GCallback)eos_cb, (__bridge void *)self);
//    g_signal_connect (G_OBJECT (bus), "message::state-changed", (GCallback)state_changed_cb, (__bridge void *)self);
//    g_signal_connect (G_OBJECT (bus), "message::duration", (GCallback)duration_cb, (__bridge void *)self);
//    g_signal_connect (G_OBJECT (bus), "message::buffering", (GCallback)buffering_cb, (__bridge void *)self);
//    g_signal_connect (G_OBJECT (bus), "message::clock-lost", (GCallback)clock_lost_cb, (__bridge void *)self);
//    gst_object_unref (bus);
//
//    /* Register a function that GLib will call 4 times per second */
//    timeout_source = g_timeout_source_new (250);
//    g_source_set_callback (timeout_source, (GSourceFunc)refresh_ui, (__bridge void *)self, NULL);
//    g_source_attach (timeout_source, context);
//    g_source_unref (timeout_source);
//
//    /* Create a GLib Main Loop and set it to run */
//    GST_DEBUG ("Entering main loop...");
//    main_loop = g_main_loop_new (context, FALSE);
//    [self check_initialization_complete];
//    g_main_loop_run (main_loop);
//    GST_DEBUG ("Exited main loop");
//    g_main_loop_unref (main_loop);
//    main_loop = NULL;
//    
//    /* Free resources */
//    g_main_context_pop_thread_default(context);
//    g_main_context_unref (context);
//    gst_element_set_state (pipeline, GST_STATE_NULL);
//    gst_object_unref (pipeline);
//    pipeline = NULL;
//    
//    ui_delegate = NULL;
////    ui_video_view = NULL;
//
//    return;
//}

@end

