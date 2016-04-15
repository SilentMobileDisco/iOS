    //
//  main.m
//  Silent Mobile Disco
//
//

#import <UIKit/UIKit.h>
#import "gst_ios_init.h"

#import "SDAppDelegate.h"

int main(int argc, char *argv[])
{
    gst_ios_init(&argc, (char **) &argv);
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SDAppDelegate class]));
    }
}
