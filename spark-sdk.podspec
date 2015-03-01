#
# Be sure to run `pod lib lint spark-sdk.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "spark-sdk"
  s.version          = "0.1.0"
  s.summary          = "A short description of spark-sdk."
  s.description      = <<-DESC
                       Cocoapod library of Spark mobile SDK for iOS
                       DESC
  s.homepage         = "https://github.com/spark/spark-sdk"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'LGPL v3'
  s.author           = { "Ido Kleinman" => "idokleinman@gmail.com" }
  s.source           = { :git => "https://github.com/spark/spark-sdk-ios.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'spark-sdk' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking'
end
