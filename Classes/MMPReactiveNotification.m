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

- (instancetype)category:(UIMutableUserNotificationCategory *)category {
    if (!self.categories) {
        self.categories = [NSMutableSet setWithObject:category];
    } else {
        if ([_categories isKindOfClass:[NSMutableSet class]]) {
            [(NSMutableSet *)_categories addObject:category];
        }
    }
    return self;
}

- (instancetype)categories:(NSSet *)categories {
    self.categories = categories;
    return self;
}

- (BOOL)notificationTypesUpToDate {
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return settings.types == self.types;
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

- (RACSignal *)userNotificationSettingsRegistration {
    return [[self.delegate rac_signalForSelector:@selector(application:didRegisterUserNotificationSettings:)
                                    fromProtocol:@protocol(UIApplicationDelegate)]
                           reduceEach:^id(id _, UIUserNotificationSettings *notificationSettings) {
                               return notificationSettings;
                           }];
}

- (RACSignal *)remoteNotifications {
    return [[self.delegate rac_signalForSelector:@selector(application:didReceiveRemoteNotification:)
                                    fromProtocol:@protocol(UIApplicationDelegate)]
                           reduceEach:^id(id _, NSDictionary *userInfo) {
                               return userInfo;
                           }];
}

- (RACSignal *)localNotifications {
    return [[self.delegate rac_signalForSelector:@selector(application:didReceiveLocalNotification:)
                                    fromProtocol:@protocol(UIApplicationDelegate)]
                           reduceEach:^id(id _, UILocalNotification *notification) {
                               return notification;
                           }];
}

- (RACSignal *)localNotificationsWithActionIdentifier:(NSString *)actionIdentifier {
    return [[[self.delegate rac_signalForSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:)
                                    fromProtocol:@protocol(UIApplicationDelegate)]
                            filter:^BOOL(RACTuple *tuple) {
                                NSString *comingIdentifier = tuple.second;
                                MMPRxN_LOG(@"Filtering coming action with identifier: %@, expecting identifier: %@", comingIdentifier, actionIdentifier)
                                return (actionIdentifier == nil || [actionIdentifier isEqualToString:comingIdentifier]);
                            }]
                            reduceEach:^id(id _, id identifier, UILocalNotification *notification, id completionHandler) {
                                return notification;
                            }];
}

- (RACSignal *)localNotificationsOnLaunch {
    return [[[self.delegate rac_signalForSelector:@selector(application:didFinishLaunchingWithOptions:)
                                     fromProtocol:@protocol(UIApplicationDelegate)]
                            filter:^BOOL(RACTuple *tuple) {
                                NSDictionary *launchOptions = tuple.second;
                                MMPRxN_LOG(@"Filtering application launch with options: %@, expecting local notification", launchOptions)
                                return (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]);
                            }]
                            reduceEach:^id(id _, NSDictionary *launchOptions) {
                                return [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
                            }];
}

- (RACSignal *)remoteNotificationsOnLaunch {
    return [[[self.delegate rac_signalForSelector:@selector(application:didFinishLaunchingWithOptions:)
                                     fromProtocol:@protocol(UIApplicationDelegate)]
             filter:^BOOL(RACTuple *tuple) {
                 NSDictionary *launchOptions = tuple.second;
                 MMPRxN_LOG(@"Filtering application launch with options: %@, expecting remote notification", launchOptions)
                 return (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]);
             }]
            reduceEach:^id(id _, NSDictionary *launchOptions) {
                return [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            }];
}

- (void)scheduleLocalNotification:(UILocalNotification *)notification {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (![self notificationTypesUpToDate]) {
        MMPRxN_LOG(@"Settings are not up-to-date, register settings before scheduling.")
        [[[self userNotificationSettingsRegistration]
                take:1]
                subscribeNext:^(UIUserNotificationSettings *notificationSettings) {
                    MMPRxN_LOG(@"Settings registered with types = %lu, now scheduling notification.", (unsigned long)notificationSettings.types)
                    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                }];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:self.types
                                                                                                              categories:self.categories]];
    } else {
        MMPRxN_LOG(@"Schedule notification immediately, settings are up-to-date.")
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
#else
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
#endif
}

- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody toBeFiredAt:(NSDate *)fireDate {
    [self scheduleLocalNotificationWithAlert:alertBody withSound:UILocalNotificationDefaultSoundName withUserInfo:nil withCategory:nil toBeFiredAt:fireDate];
}

- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody
                              withUserInfo:(NSDictionary *)userInfo
                               toBeFiredAt:(NSDate *)fireDate {
    [self scheduleLocalNotificationWithAlert:alertBody withSound:UILocalNotificationDefaultSoundName withUserInfo:userInfo withCategory:nil toBeFiredAt:fireDate];
}

- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody
                                 withSound:(NSString *)soundName
                              withUserInfo:(NSDictionary *)userInfo
                              withCategory:(NSString *)category
                               toBeFiredAt:(NSDate *)fireDate {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.fireDate = fireDate;
    localNotification.alertBody = alertBody;
    localNotification.soundName = soundName;
    if (userInfo) {
        localNotification.userInfo = userInfo;
    }
    if (category) {
        localNotification.category = category;
    }
    [self scheduleLocalNotification:localNotification];
}

@end
