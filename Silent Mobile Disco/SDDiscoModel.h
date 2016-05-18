//
//  SDDiscoModel.h
//  Silent Mobile Disco
//
//  Created by Oren Berkowitz on 4/16/16.
//  Copyright © 2016 Silent Mobile Disco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDDiscoModel : NSObject

@property (copy) NSString *ip;
@property (copy) NSString *port;
@property (copy) NSString *name;
@property (copy) NSString *caps;
@property NSInteger baseTime;


- (instancetype)initWithName:(NSString *)name ip:(NSString *)ip
                                            port:(NSString *)port
                                            caps:(NSString *)caps
                                        baseTime:(NSInteger)baseTime;
- (NSString *)uri;

@end
