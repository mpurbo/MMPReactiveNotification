//
//  MMPReactiveNotification.h
//
//  The MIT License (MIT)
//  Copyright (c) 2015 Mamad Purbo, purbo.org
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface MMPLocalNotificationSpec : NSObject

- (id)initWithNotification:(UILocalNotification *)notification;

// Composing
- (instancetype)withAlertBody:(NSString *)alertBody;
- (instancetype)withAlertAction:(NSString *)alertAction;
- (instancetype)withAlertTitle:(NSString *)alertTitle;
- (instancetype)withAlertLaunchImage:(NSString *)alertLaunchImage;
- (instancetype)withCategory:(NSString *)category;
- (instancetype)hasAction:(BOOL)hasAction;

// Other configurations
- (instancetype)withApplicationIconBadgeNumber:(NSInteger)applicationIconBadgeNumber;
- (instancetype)withSoundName:(NSString *)soundName;
- (instancetype)withUserInfo:(NSDictionary *)userInfo;

// Scheduling
- (instancetype)timeZone:(NSTimeZone *)timeZone;
- (instancetype)fireAt:(NSDate *)date;
- (instancetype)fireDailyAtHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;

- (void)schedule;

@end

@interface MMPReactiveNotification : NSObject

+ (instancetype)service;

// =============================================================================
// Settings
// =============================================================================

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (instancetype)notificationTypes:(UIUserNotificationType)types;
- (instancetype)category:(UIMutableUserNotificationCategory *)category;
- (instancetype)categories:(NSSet *)categories;
#else
- (instancetype)notificationTypes:(UIRemoteNotificationType)types;
#endif

// =============================================================================
// Settings
// =============================================================================

/**
 *  Register for remote notification based. Returned signal produces remote 
 *  notification token.
 *
 *  @return Signal producing remote notification token as NSData.
 */
- (RACSignal *)remoteRegistration;

/**
 *  Returns a signal that will produces an NSDictionary every time the app 
 *  receives remote push notification.
 *
 *  @return Signal producing NSDictionary push data.
 */
- (RACSignal *)remoteNotifications;

/**
 *  Returns a signal that will produces an UILocalNotification every time the 
 *  app receives local notification.
 *
 *  @return Signal producing UILocalNotification.
 */
- (RACSignal *)localNotifications;
- (RACSignal *)localNotificationsWithActionIdentifier:(NSString *)actionIdentifier;
- (RACSignal *)localNotificationsOnLaunch;

- (RACSignal *)remoteNotificationsOnLaunch;

- (RACSignal *)userNotificationSettingsRegistration;

/**
 *  Simple wrapper of UIApplication's scheduleLocalNotification:
 *
 *  @param notification local notification to be scheduled.
 */
- (void)scheduleLocalNotification:(UILocalNotification *)notification;
/*
- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody toBeFiredAt:(NSDate *)fireDate;
- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody
                              withUserInfo:(NSDictionary *)userInfo
                               toBeFiredAt:(NSDate *)fireDate;
- (void)scheduleLocalNotificationWithAlert:(NSString *)alertBody
                                 withSound:(NSString *)soundName
                              withUserInfo:(NSDictionary *)userInfo
                              withCategory:(NSString *)category
                               toBeFiredAt:(NSDate *)fireDate;
- (void)scheduleDailyLocalNotificationWithAlert:(NSString *)alertBody
                                      withSound:(NSString *)soundName
                                   withUserInfo:(NSDictionary *)userInfo
                                   withCategory:(NSString *)category
                            withIconBadgeNumber:(NSInteger)applicationIconBadgeNumber
                                toBeFiredAtHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second
                                     inTimeZone:(NSTimeZone *)timeZone;
*/

@end
