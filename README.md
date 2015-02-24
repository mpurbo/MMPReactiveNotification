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

Use the `MMPReactiveNotification` singleton instance anywhere in your application to subscribe to an appropriate signal. For example, following example shows how to use `remoteRegistration` signal to register for remote push notification and receive the push token:
```objc
// import the header
#import <MMPReactiveNotification/MMPReactiveNotification.h>

[[[MMPReactiveNotification instance]
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
[[[MMPReactiveNotification instance]
                           remoteNotifications]
                           subscribeNext:^(NSDictionary *pushData) {
                               NSLog(@"Receiving push: %@", pushData);
                           }];
```

## Contact

MMPReactiveNotification is maintained by [Mamad Purbo](https://twitter.com/purubo)

## License

MMPReactiveNotification is available under the MIT license. See the LICENSE file for more info.
