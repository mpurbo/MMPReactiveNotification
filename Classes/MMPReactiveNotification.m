//
//  MMPReactiveNotification.m
//  GeocoreDemo
//
//  Created by Purbo Mohamad on 2/21/15.
//  Copyright (c) 2015 MapMotion. All rights reserved.
//

#import "MMPReactiveNotification.h"

@interface MMPReactiveNotification()

@property (nonatomic, strong) id<UIApplicationDelegate> appDelegate;

@end

@implementation MMPReactiveNotification

static id _shared = nil;

+ (instancetype)instanceWithAppDelegate:(id<UIApplicationDelegate>)appDelegate {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shared = [[super alloc] initSingletonInstanceWithAppDelegate:appDelegate];
    });
    return _shared;
}

+ (instancetype)instance {
    return _shared;
}

- (instancetype)initSingletonInstanceWithAppDelegate:(id<UIApplicationDelegate>)appDelegate {
    if (self = [super init]) {
        self.appDelegate = appDelegate;
    }
    return self;
}

- (RACSignal *)remoteRegistration {
    return nil;
}

- (RACSignal *)remoteNotifications {
    return nil;
}

@end
