#
# Be sure to run `pod lib lint spark-sdk.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "Spark-SDK"
    s.version          = "0.1.2"
    s.summary          = "Spark mobile SDK for interacting with connected products via Spark Cloud"
    s.description      = <<-DESC
                        Cocoapod library of Spark mobile SDK for iOS
                        Spark mobile SDK for iOS devices interacting with connected products via Spark Cloud
                        This library will allow you to easily perform the following:
                        - User session management for Spark cloud
                        - Read/write data to/from Spark Core, Photon or Electron devices
                        - Publish and subscribe events to/from the cloud or to/from devices (beta)
                        DESC
    s.homepage         = "https://github.com/spark/spark-sdk-ios"
    # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
    s.license          = 'LGPL v3'
    s.author           = { "Ido Kleinman" => "ido@spark.io" }
    s.source           = { :git => "https://github.com/spark/spark-sdk-ios.git", :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

    s.platform     = :ios, '7.0'
    s.requires_arc = true

    s.public_header_files = 'Pod/Classes/*.h'
    s.source_files = 'Pod/Classes/Spark-SDK.h'

    s.subspec 'Helpers' do |ss|
        ss.source_files = 'Pod/Classes/KeychainItemWrapper.{h,m}', 'Pod/Classes/Reachability.{h,m}'
        ss.ios.frameworks = 'SystemConfiguration', 'Security'
    end

    s.subspec 'SDK' do |ss|
        ss.source_files = 'Pod/Classes/Spark*.{h,m}'
        ss.dependency 'AFNetworking'
        ss.dependency 'Spark-SDK/Helpers'
    end


    s.resource_bundles = {
        'spark-sdk' => ['Pod/Assets/*.png']
    }

    # s.frameworks = 'SystemConfiguration', 'Security'

end
