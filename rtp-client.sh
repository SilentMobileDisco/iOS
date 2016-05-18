#!/bin/sh 
# 
# A simple RTP receiver 

AUDIO_CAPS="application/x-rtp,media=(string)audio,clock-rate=(int)44100,encoding-name=(string)MPEG4-GENERIC,encoding-params=(string)1,streamtype=(string)5,profile-level-id=(string)2,mode=(string)AAC-hbr,config=(string)1208,sizelength=(string)13,indexlength=(string)3,indexdeltalength=(string)3,ssrc=(uint)853015980,payload=(int)96,clock-base=(uint)2040203639,seqnum-base=(uint)52067" 
#AUDIO_CAPS="application/x-rtp, media=(string)audio, clock-rate=(int)44100, encoding-name=(string)MPEG4-GENERIC, encoding-params=(string)1, streamtype=(string)5, profile-level-id=(string)2, mode=(string)AAC-hbr, config=(string)1208, sizelength=(string)13, indexlength=(string)3, indexdeltalength=(string)3, ssrc=(uint)853015980, payload=(int)96, clock-base=(uint)2040203639, seqnum-base=(uint)52067" 

AUDIO_DEC="rtppcmadepay ! alawdec" 

AUDIO_SINK="autoaudiosink" 

# the destination machine to send RTCP to. This is the address of the sender and 
# is used to send back the RTCP reports of this receiver. If the data is sent 
# from another machine, change this address. 
DEST=127.0.0.1 
                            
gst-launch-1.0 rtpbin name=rtp udpsrc caps=$AUDIO_CAPS port=5002 ! rtp.recv_rtp_sink_0 rtp. ! $AUDIO_DEC ! $AUDIO_SINK udpsrc port=5003 ! rtp.recv_rtcp_sink_0 rtp.send_rtcp_src_0 ! udpsink port=5007 host=$DEST sync=false async=false 

# 
