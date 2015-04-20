#
# Be sure to run `pod lib lint Spark-SDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "Spark-SDK"
    s.version          = "0.2.0"
    s.summary          = "Spark iOS SDK for interacting with Spark powered connected products via Spark Cloud"
    s.description      = <<-DESC
                        Spark iOS SDK Cocoapod library
                        The Spark iOS SDK enables iOS apps to interact with Spark-powered connected products via the Spark Cloud.
                        Library will allow you to easily manage active user sessions to Spark cloud, query for device info,
                        read and write data to/from Spark Core/Photon devices and (via exposed variables and functions)
                        publish and subscribe events to/from the cloud or to/from devices (coming soon).
                        DESC
    s.homepage         = "https://github.com/spark/spark-sdk-ios"
    # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
    s.license          = 'LGPL v3'
    s.author           = { "Ido Kleinman" => "ido@spark.io" }
    s.source           = { :git => "https://github.com/spark/Spark-SDK-ios.git", :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

    s.platform     = :ios, '7.1'
    s.requires_arc = true

    s.public_header_files = 'Pod/Classes/*.h'
    s.source_files = 'Pod/Classes/Spark-SDK.h'

    s.subspec 'Helpers' do |ss|
        ss.source_files = 'Pod/Classes/Helpers/KeychainItemWrapper.{h,m}', 'Pod/Classes/Reachability.{h,m}'
        ss.ios.frameworks = 'SystemConfiguration', 'Security'
    end

    s.subspec 'SDK' do |ss|
        ss.source_files = 'Pod/Classes/SDK/Spark*.{h,m}'
        ss.dependency 'AFNetworking'
        ss.dependency 'Spark-SDK/Helpers'
    end


    s.resource_bundles = {
        'Spark-SDK' => ['Pod/Assets/*.*']
    }

    # s.frameworks = 'SystemConfiguration', 'Security'

end
