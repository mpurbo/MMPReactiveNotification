//
//  MMPReactiveNotification.m
//  GeocoreDemo
//
//  Created by Purbo Mohamad on 2/21/15.
//  Copyright (c) 2015 MapMotion. All rights reserved.
//

#import "MMPReactiveNotification.h"

@interface MMPReactiveNotification()

@end

@implementation MMPReactiveNotification

+ (instancetype)instance {
    static dispatch_once_t once;
    static id shared = nil;
    dispatch_once(&once, ^{
        shared = [[super alloc] initSingletonInstance];
    });
    return shared;
}

- (instancetype)initSingletonInstance {
    if (self = [super init]) {
    }
    return self;
}

- (RACSignal *)remoteRegistration {
    RACMulticastConnection *conn = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        UIApplication *app = [UIApplication sharedApplication];
        UIResponder<UIApplicationDelegate> *delegate = app.delegate;
        
        RACSignal *reg = [[delegate rac_signalForSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
                                             fromProtocol:@protocol(UIApplicationDelegate)]
                                    reduceEach:^id(id _, NSData *deviceToken) {
                                        return deviceToken;
                                    }];
        RACSignal *err = [[delegate rac_signalForSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)
                                             fromProtocol:@protocol(UIApplicationDelegate)]
                                    reduceEach:^id(id _, NSError *error) {
                                        return error;
                                    }];
        
        [reg subscribeNext:^(NSData *deviceToken) {
            [subscriber sendNext:deviceToken];
            [subscriber sendCompleted];
        }];
        
        [err subscribeNext:^(NSError *error) {
            [subscriber sendError:error];
        }];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
                                                                                           UIUserNotificationTypeBadge |
                                                                                           UIUserNotificationTypeSound
                                                                                categories:nil]];
        [app registerForRemoteNotifications];
#else
        if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge |
                                                                                                UIRemoteNotificationTypeSound |
                                                                                                UIRemoteNotificationTypeAlert)
                                                                                    categories:nil]];
            [app registerForRemoteNotifications];
        } else {
            [app registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                     UIRemoteNotificationTypeSound |
                                                     UIRemoteNotificationTypeAlert)];
        }
#endif
        
        return [RACDisposable disposableWithBlock:^{
        }];
        
    }] publish];
    
    [conn connect];
    return conn.signal;
}

- (RACSignal *)remoteNotifications {
    UIApplication *app = [UIApplication sharedApplication];
    UIResponder<UIApplicationDelegate> *delegate = app.delegate;
    return [[delegate rac_signalForSelector:@selector(application:didReceiveRemoteNotification:)
                               fromProtocol:@protocol(UIApplicationDelegate)]
                      reduceEach:^id(id _, NSDictionary *userInfo) {
                          return userInfo;
                      }];
}

@end
