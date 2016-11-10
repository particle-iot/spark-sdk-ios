Pod::Spec.new do |s|
    s.name             = "Spark-SDK"
    s.version          = "0.6.0"
    s.summary          = "Particle iOS Cloud SDK for interacting with Particle powered devices (Core/Photon/Electron)"
    s.description      = <<-DESC
                        Particle (formerly Spark) iOS Cloud SDK Cocoapod library
                        The Particle iOS Cloud SDK enables iOS apps to interact with Particle-powered connected products via the Particle Cloud.
                        Library will enable your app to easily manage active user sessions to the Particle cloud, query for device's type, info, read and write data to and from the Core, Photon and Electron devices (via exposed firmware variables and functions) as well as publish/subscribe device and cloud events.
                        DESC
    s.homepage         = "https://github.com/spark/spark-sdk-ios"
    s.screenshots      = "http://i59.tinypic.com/mrthqc.jpg"
    s.license          = 'Apache 2.0'
    s.author           = { "Particle" => "ido@particle.io" }
    s.source           = { :git => "https://github.com/spark/Spark-SDK-ios.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/particle'

    s.platform     = :ios, '8.0'
    s.requires_arc = true

    s.public_header_files = 'Pod/Classes/*.h'
    s.source_files = 'Pod/Classes/*.h'

    s.subspec 'Helpers' do |ss|
        ss.source_files = 'Pod/Classes/Helpers/*.{h,m}'
        ss.ios.frameworks = 'SystemConfiguration', 'Security'
    end

    s.subspec 'SDK' do |ss|
        ss.source_files = 'Pod/Classes/SDK/Spark*.{h,m}'
        ss.dependency 'AFNetworking', '~> 3.0'
        ss.dependency 'Spark-SDK/Helpers'
    end

    # s.frameworks = 'SystemConfiguration', 'Security'

end
