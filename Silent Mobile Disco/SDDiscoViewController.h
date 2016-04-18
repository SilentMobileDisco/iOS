//
//  SDDiscoViewController.h
//  Silent Mobile Disco
//
//  Created by Oren Berkowitz on 4/16/16.
//  Copyright © 2016 Silent Mobile Disco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDDiscoModel.h"
#import "GStreamerBackendDelegate.h"

@interface SDDiscoViewController : UIViewController <GStreamerBackendDelegate> {
    IBOutlet UILabel *message_label;
    IBOutlet UILabel *dj_name;
    IBOutlet UIBarButtonItem *play_button;
    IBOutlet UIBarButtonItem *pause_button;
}

@property SDDiscoModel *disco;

- (IBAction) onPlay:(id) sender;
- (IBAction) onPause:(id) sender;

/* From GStreamerBackendDelegate */
-(void) gstreamerInitialized;
-(void) gstreamerSetUIMessage:(NSString *)message;

@end
