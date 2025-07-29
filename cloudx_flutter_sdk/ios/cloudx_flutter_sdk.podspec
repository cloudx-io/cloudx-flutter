Pod::Spec.new do |s|
  s.name             = 'cloudx_flutter_sdk'
  s.version          = '1.0.6'
  s.summary          = 'Flutter SDK wrapper for CloudX Core Objective-C SDK'
  s.description      = <<-DESC
A Flutter plugin that provides a wrapper around the CloudX Core Objective-C SDK,
exposing all ad types (banner, interstitial, rewarded, native, MREC) and SDK initialization.
                       DESC
  s.homepage         = 'https://github.com/cloudx-xenoss/cloudx_flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'CloudXCore', '~> 1.1.40'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'NO', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end 