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
    s.version          = "0.2.10"
    s.summary          = "Particle iOS Cloud SDK for interacting with products/project powered by Cores/Photons via Particle Cloud"
    s.description      = <<-DESC
                        Particle (formerly Spark) iOS Cloud SDK Cocoapod library
                        The Particle iOS Cloud SDK enables iOS apps to interact with Particle-powered connected products via the Particle Cloud.
                        Library will allow you to easily manage active user sessions to Particle cloud, query for device info,
                        read and write data to/from Spark Core/Photon devices and (via exposed variables and functions)
                        publish and subscribe events to/from the cloud or to/from devices (coming soon).
                        notice: Spark has been rebranded as Particle
                        DESC
    s.homepage         = "https://github.com/spark/spark-sdk-ios"
    s.screenshots      = "http://i59.tinypic.com/mrthqc.jpg"
    s.license          = 'Apache 2.0'
    s.author           = { "Particle" => "ido@particle.io" }
    s.source           = { :git => "https://github.com/spark/Spark-SDK-ios.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/particle'

    s.platform     = :ios, '7.1'
    s.requires_arc = true

    s.public_header_files = 'Pod/Classes/*.h'
    s.source_files = 'Pod/Classes/Spark-SDK.h'

    s.subspec 'Helpers' do |ss|
        ss.source_files = 'Pod/Classes/Helpers/*.{h,m}'
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
