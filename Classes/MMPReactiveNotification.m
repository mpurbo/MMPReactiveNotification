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

@interface MMPLocalNotificationSpec()

@property (nonatomic, strong) UILocalNotification *localNotification;

@end

@implementation MMPLocalNotificationSpec

- (id)init {
    if (self = [super init]) {
        self.localNotification = [UILocalNotification new];
    }
    return self;
}

- (id)initWithNotification:(UILocalNotification *)notification {
    if (self = [super init]) {
        self.localNotification = notification;
    }
    return self;
}

- (instancetype)withAlertBody:(NSString *)alertBody {
    _localNotification.alertBody = alertBody;
    return self;
}

- (instancetype)withAlertAction:(NSString *)alertAction {
    _localNotification.alertAction = alertAction;
    return self;
}

- (instancetype)withAlertTitle:(NSString *)alertTitle {
    _localNotification.alertTitle = alertTitle;
    return self;
}

- (instancetype)withAlertLaunchImage:(NSString *)alertLaunchImage {
    _localNotification.alertLaunchImage = alertLaunchImage;
    return self;
}

- (instancetype)withCategory:(NSString *)category {
    _localNotification.category = category;
    return self;
}

- (instancetype)hasAction:(BOOL)hasAction {
    _localNotification.hasAction = hasAction;
    return self;
}

- (instancetype)withApplicationIconBadgeNumber:(NSInteger)applicationIconBadgeNumber {
    _localNotification.applicationIconBadgeNumber = applicationIconBadgeNumber;
    return self;
}

- (instancetype)withSoundName:(NSString *)soundName {
    _localNotification.soundName = soundName;
    return self;
}

- (instancetype)withUserInfo:(NSDictionary *)userInfo {
    _localNotification.userInfo = userInfo;
    return self;
}

- (instancetype)fireAt:(NSDate *)date {
    _localNotification.fireDate = date;
    return self;
}

- (instancetype)fireDailyAtHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond) fromDate:[NSDate new]];
#else
    NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:[NSDate new]];
#endif
    if (_localNotification.timeZone != nil) {
        gregorian.timeZone = _localNotification.timeZone;
    }
    
    [components setHour:-[components hour] + hour];
    [components setMinute:-[components minute] + minute];
    [components setSecond:-[components second] + second];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    _localNotification.repeatInterval = NSCalendarUnitDay;
#else
    _localNotification.repeatInterval = NSDayCalendarUnit;
#endif    
    return [self fireAt:[gregorian dateByAddingComponents:components toDate:[NSDate new] options:0]];
}

- (instancetype)timeZone:(NSTimeZone *)timeZone {
    _localNotification.timeZone = timeZone;
    return self;
}

- (void)schedule {
    [[MMPReactiveNotification service] scheduleLocalNotification:_localNotification];
}

@end


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
        if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:self.types
                                                                                    categories:self.categories]];
            [app registerForRemoteNotifications];
        } else {
            [app registerForRemoteNotificationTypes:self.types];
        }
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

@end
