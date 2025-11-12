Pod::Spec.new do |s|
  s.name             = 'cloudx_flutter'
  s.version          = '0.16.0'
  s.summary          = 'Flutter SDK wrapper for CloudX (Android only)'
  s.description      = <<-DESC
A Flutter plugin for CloudX ad monetization. Currently supports Android only.
iOS support is in development and not yet available for production use.
For production iOS access, please contact the CloudX team.
                       DESC
  s.homepage         = 'https://github.com/cloudx-io/cloudx-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CloudX' => 'support@cloudx.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  # CloudXCore dependency removed - iOS SDK not yet ready for production
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'NO', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end 