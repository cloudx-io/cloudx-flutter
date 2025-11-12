Pod::Spec.new do |s|
  s.name             = 'cloudx_flutter'
  s.version          = '0.14.0'
  s.summary          = 'Flutter SDK wrapper for CloudX Core Objective-C SDK'
  s.description      = <<-DESC
A Flutter plugin that provides a complete wrapper around the CloudX Core Objective-C SDK,
exposing all ad types (banner, interstitial, rewarded, native, MREC), privacy & compliance APIs
(CCPA, GDPR, COPPA, GPP), targeting APIs, and comprehensive ad lifecycle callbacks.
                       DESC
  s.homepage         = 'https://github.com/cloudx-io/cloudx-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'CloudXCore', '~> 1.1.60'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'NO', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end 