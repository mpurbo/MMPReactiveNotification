# MMPReactiveNotification

MMPReactiveNotification is a reactive library providing signals for local and remote push notifications.

Features:
* No more notification related delegate methods, registration and notifications are available as signals.
* Signal for remote push registration.
* Signal for receiving remote notifications.
* Signal for receiving local notifications.

## Installation

MMPReactiveNotification is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:
```
pod 'MMPReactiveNotification'
```

## Usage

Use `MMPReactiveNotification` class method `service` anywhere in your application to subscribe to an appropriate signal. For example, following example shows how to use `remoteRegistration` signal to register for remote push notification with [default settings](#custom-settings) and receive the push token:
```objc
// import the header
#import <MMPReactiveNotification/MMPReactiveNotification.h>

[[[MMPReactiveNotification service]
                           remoteRegistration]
                           subscribeNext:^(NSData *tokenData) {
                               NSLog(@"Receiving push token: %@", tokenData);
                               // Send the push token to your server
                           }
                           error:^(NSError *error) {
                               NSLog(@"Push registration error: %@", error);
                           }];

```

To receive remote push notifications, use `remoteNotifications` method:
```objc
[[[MMPReactiveNotification service]
                           remoteNotifications]
                           subscribeNext:^(NSDictionary *pushData) {
                               NSLog(@"Receiving push: %@", pushData);
                           }];
```

## Custom Settings

Default settings for remote push registration are:
- Enable alert, badge, and sound (see [UIUserNotificationType](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIUserNotificationSettings_class/index.html#//apple_ref/c/tdef/UIUserNotificationType)).
- No custom actions (see [UIUserNotificationCategory](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIUserNotificationCategory_class/index.html#//apple_ref/occ/cl/UIUserNotificationCategory)).

To customize these settings, use `notificationTypes` and `categories` methods as shown in the following example:
```objc
// only enable alert and badge
[[[[MMPReactiveNotification service]
                            notificationTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge]
                            remoteRegistration]
                            subscribeNext:^(NSData *tokenData) {
                                NSLog(@"Receiving push token: %@", tokenData);
                               // Send the push token to your server
                            }];
```

## Roadmap

* 0.3: Remote notification with custom handler, `didFinishLaunchingWithOptions` integration.
* 0.4: Local notifications.

## Contact

MMPReactiveNotification is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveNotification is available under the MIT license. See the LICENSE file for more info.
