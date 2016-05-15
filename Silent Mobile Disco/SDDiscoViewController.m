//
//  SDDiscoViewController.m
//  Silent Mobile Disco
//
//  Created by Oren Berkowitz on 4/16/16.
//  Copyright © 2016 Silent Mobile Disco. All rights reserved.
//

#import "SDDiscoViewController.h"
#import "GStreamerBackend.h"
#import "SDDiscoModel.h"

@interface SDDiscoViewController () <GStreamerBackendDelegate> {
    GStreamerBackend *gst_backend;
}

@end

@implementation SDDiscoViewController

@synthesize disco;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    play_button.enabled = FALSE;
    pause_button.enabled = FALSE;

    gst_backend = [[GStreamerBackend alloc] init:self];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)onPause:(id)sender {
    [gst_backend pause];
}

- (void)onPlay:(id)sender {
    [gst_backend play];
}

-(void) gstreamerInitialized{
    dispatch_async(dispatch_get_main_queue(), ^{
        play_button.enabled = TRUE;
        pause_button.enabled = TRUE;
        message_label.text = @"Ready";
//        [gst_backend setUri:[self.disco uri]];
        dj_name.text = self.disco.name;
    });

}
-(void) gstreamerSetUIMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        message_label.text = message;
    });
}



@end
