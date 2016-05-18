#import <Foundation/Foundation.h>
#import "GStreamerBackendDelegate.h"

@interface GStreamerBackend : NSObject

/* Initialization method. Pass the delegate that will take care of the UI.
 * This delegate must implement the GStreamerBackendDelegate protocol.
 */
-(id) init:(id)uiDelegate ip:(NSString *)ip caps:(NSString *)caps baseTime:(NSInteger)base;

/* Quit the main loop and free all resources, including the pipeline and
 * the references to the ui delegate and the UIView used for rendering, so
 * these objects can be deallocated. */
-(void) deinit;

/* Set the pipeline to PLAYING */
-(void) play;

/* Set the pipeline to PAUSED */
-(void) pause;

/* Set the URI to be played */
-(void) setUri:(NSString*)uri;

@property (strong, nonatomic) NSString *ip;


@end