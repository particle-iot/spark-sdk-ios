<p align="center" >
<img src="https://s3.amazonaws.com/spark-website/spark.png" alt="Spark" title="Spark">
</p>

<!---
(Update link)
[![Build Status](https://travis-ci.org/AFNetworking/AFNetworking.svg)](https://travis-ci.org/Spark-SDK/Spark-SDK)
-->
# Spark iOS Cloud SDK (beta)
The Spark iOS Cloud SDK enables iOS apps to interact with Spark-powered connected products via the Spark Cloud.
Library will allow you to easily manage active user sessions to Spark cloud, query for device info,
read and write data to/from Spark Core/Photon devices and (via exposed variables and functions)
publish and subscribe events to/from the cloud or to/from devices (coming soon).

## How To Get Started

- [Download Spark iOS Cloud SDK](https://github.com/spark/spark-sdk-ios/archive/master.zip) and try out the included iOS example app
- Or perform the installation step described under the **Installation** section below

## Usage

_Full documentation coming soon_

Meanahile you can check out the [Reference in Cocoadocs website](http://cocoadocs.org/docsets/Spark-SDK/) or consult the javadoc style comments in `SparkCloud.h` and `SparkDevice.h` for each public method.
If Spark iOS Cloud SDK installation completed successfully - you should be able to press `Esc` to get an auto-complete hints from XCode for each cloud and device method.

## Communication

- If you **need help**, use [Our community website](http://community.spark.io), use the `mobile` category for dicussion/troubleshooting iOS apps using the Spark iOS Cloud SDK.
- If you are certain you **found a bug**, _and can provide steps to reliably reproduce it_, open an issue, label it as `bug`.
- If you **have a feature request**, open an issue with an `enhancement` label on it
- If you **want to contribute**, submit a pull request, be sure to check out spark.github.io for our contribution guidelines, and please sign the [CLA](https://docs.google.com/a/spark.io/forms/d/1_2P-vRKGUFg5bmpcKLHO_qNZWGi5HKYnfrrkd-sbZoA/viewform). 

## Installation

Spark iOS Cloud SDK is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile on main project folder:

```ruby
pod "Spark-SDK"
```

and then run `pod update`. A new `.xcworkspace` file will be created for you to open by Cocoapods, open that file workspace file in XCode and you can start interacting with Spark cloud and devices by
adding `#import "Spark-SDK.h"`. (that is not required for swift projects)


#### Support for Swift projects
To use Spark-SDK from within Swift based projects [read here](http://swiftalicio.us/2014/11/using-cocoapods-from-swift/), 
also be sure the check out [Apple documentation](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithObjective-CAPIs.html) on this matter.
_Notice_ that we've included the required bridging header file in the SDK, you just need to copy it to your project add it as the active bridging header file in the project settings as described in the link above.
We also have an example app [here](https://github.com/spark/spark-setup-ios-example), this app also demonstrates the Spark DeviceSetup library usage

## Maintainers

- [Ido Kleinman](https:/www.github.com/idokleinman)

## License

Spark iOS Cloud SDK is available under the LGPL v3 license. See the LICENSE file for more info.
