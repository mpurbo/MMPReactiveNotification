//
//  MMPReactiveNotification.m
//
//  The MIT License (MIT)
//  Copyright (c) 2015 Mamad Purbo, purbo.org
//

#import "MMPReactiveNotification.h"

#ifdef DEBUG
#   define MMPRxN_LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MMPRxN_LOG(...)
#endif

@interface MMPReactiveNotification()

@property (nonatomic, assign) UIResponder<UIApplicationDelegate> *delegate;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property (nonatomic, assign) UIUserNotificationType types;
@property (nonatomic, copy) NSSet *categories;
#else
@property (nonatomic, assign) UIRemoteNotificationType types;
#endif

@end

@implementation MMPReactiveNotification

- (id)init {
    if (self = [super init]) {
        [self defaultSettings];
        
        UIApplication *app = [UIApplication sharedApplication];
        self.delegate = app.delegate;
    }
    return self;
}

- (void)defaultSettings {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    self.types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    self.categories = nil;
#else
    self.types = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert;
#endif
}

+ (instancetype)service {
    return [MMPReactiveNotification new];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (instancetype)notificationTypes:(UIUserNotificationType)types {
    self.types = types;
    return self;
}

- (instancetype)categories:(NSSet *)categories {
    self.categories = categories;
    return self;
}

#else

- (instancetype)notificationTypes:(UIRemoteNotificationType)types {
    self.types = types;
    return self;
}

#endif

- (RACSignal *)remoteRegistration {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        RACSignal *reg = [[self.delegate rac_signalForSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
                                                  fromProtocol:@protocol(UIApplicationDelegate)]
                                         reduceEach:^id(id _, NSData *deviceToken) {
                                             return deviceToken;
                                         }];
        RACSignal *err = [[self.delegate rac_signalForSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)
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
        
        MMPRxN_LOG(@"Registering for push.")
        
        UIApplication *app = [UIApplication sharedApplication];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:self.types
                                                                                categories:self.categories]];
        [app registerForRemoteNotifications];
#else
        [app registerForRemoteNotificationTypes:self.types];
#endif
        
        return [RACDisposable disposableWithBlock:^{
            MMPRxN_LOG(@"Disposing subscriber for push registration.")
        }];
        
    }];
}

- (RACSignal *)remoteNotifications {
    return [[self.delegate rac_signalForSelector:@selector(application:didReceiveRemoteNotification:)
                                    fromProtocol:@protocol(UIApplicationDelegate)]
                           reduceEach:^id(id _, NSDictionary *userInfo) {
                               return userInfo;
                           }];
}

@end
