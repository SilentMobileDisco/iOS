    //
//  main.m
//  Four in a Row
//
//  Created by Bart Jacobs on 11/04/13.
//  Copyright (c) 2013 Mobile Tuts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "gst_ios_init.h"

#import "MTAppDelegate.h"

int main(int argc, char *argv[])
{
    gst_ios_init(&argc, (char **) &argv);
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([MTAppDelegate class]));
    }
}
