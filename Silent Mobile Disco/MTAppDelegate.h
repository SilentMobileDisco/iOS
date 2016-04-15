//
//  MTAppDelegate.h
//  Four in a Row
//
//  Created by Bart Jacobs on 11/04/13.
//  Copyright (c) 2013 Mobile Tuts. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTViewController;

@interface MTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MTViewController *viewController;

@end
