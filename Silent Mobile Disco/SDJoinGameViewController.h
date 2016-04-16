//
//  SDJoinGameViewController.h
//  Silent Mobile Disco
//
//

#import <UIKit/UIKit.h>
#import "GStreamerBackend.h"

@interface SDJoinGameViewController : UITableViewController <GStreamerBackendDelegate> {
    GStreamerBackend *gst_backend;
}

@end
