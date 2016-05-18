#!/bin/sh 
# 
# A simple RTP server 

# change this to send the RTP data and RTCP to another host 
DEST=127.0.0.1 

AELEM=audiotestsrc 

#AAC encode from the source 
ASOURCE="$AELEM ! audioconvert" 
AENC="alawenc ! rtppmcapay " 


gst-launch-1.0 rtpbin name=rtp $ASOURCE ! $AENC ! rtp.send_rtp_sink_0  rtp.send_rtp_src_0 ! udpsink port=5002 host=$DEST rtp.send_rtcp_src_0 ! udpsink port=5003 host=$DEST sync=false async=false udpsrc port=5007 ! rtp.recv_rtcp_sink_0 
