//
//  MMPReactiveNotification.h
//  GeocoreDemo
//
//  Created by Purbo Mohamad on 2/21/15.
//  Copyright (c) 2015 MapMotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface MMPReactiveNotification : NSObject

+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

+ (instancetype)instanceWithAppDelegate:(id<UIApplicationDelegate>)appDelegate;
+ (instancetype)instance;

- (RACSignal *)remoteRegistration;
- (RACSignal *)remoteNotifications;

@end
