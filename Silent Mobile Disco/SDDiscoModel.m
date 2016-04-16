//
//  SDDiscoModel.m
//  Silent Mobile Disco
//
//  Created by Oren Berkowitz on 4/16/16.
//  Copyright © 2016 Silent Mobile Disco. All rights reserved.
//

#import "SDDiscoModel.h"

@implementation SDDiscoModel

- (id)initWithName:(NSString *)name ip:(NSString *)ip port:(NSString *)port {
    self = [super init];
    if (self) {
        _name = name;
        _ip = ip;
        _port = port;
    }
    return self;
}

@end
