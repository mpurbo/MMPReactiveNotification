Pod::Spec.new do |s|
  s.name             = "MMPReactiveNotification"
  s.version          = "0.2.0"
  s.summary          = "Local and remote push notifications as reactive signals with ReactiveCocoa"
  s.description      = <<-DESC
                       MMPReactiveNotification is a reactive library providing signals for local and remote push notifications.

                       Features:
                       * No more notification related delegate methods, registration and notifications are available as signals.
                       * Signal for remote push registration.
                       * Signal for receiving remote notifications.
                       * Signal for receiving local notifications.
                       DESC
  s.homepage         = "https://github.com/mpurbo/MMPReactiveNotification"
  s.license          = 'MIT'
  s.author           = { "Mamad Purbo" => "m.purbo@gmail.com" }
  s.source           = { :git => "https://github.com/mpurbo/MMPReactiveNotification.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/purubo'

  s.platform         = :ios
  s.ios.deployment_target = '7.0'
  s.source_files     = 'Classes'
  s.dependency 'ReactiveCocoa'
  s.requires_arc     = true    
end
