#Change Log
All notable changes to this project will be documented in this file.
Particle iOS Cloud SDK adheres to [Semantic Versioning](http://semver.org/).

---

## [0.3.3](https://github.com/spark/spark-sdk-ios/releases/tag/0.3.0) (2015-07-22)

* Fix crash in case error object is nil across cloud SDK functions failure blocks

* Get rid of compiler warnings

## [0.3.2](https://github.com/spark/spark-sdk-ios/releases/tag/0.3.0) (2015-07-22)

* README documentation for OAuth credentials 

* Signup customers/password reset for user

* Detailed error logging from cloud SDK functions

## [0.3.1](https://github.com/spark/spark-sdk-ios/releases/tag/0.3.0) (2015-07-22)

* document generateClaimCodeForOrganization func

* isLoggedin flag

* remove OAuth credentials plist file in favor of new class variables (used to 'feed' client/secret to SparkCloud class)

* README fixes, CHANGELOG added

## [0.3.0](https://github.com/spark/spark-sdk-ios/releases/tag/0.3.0) (2015-07-22)

* Events pub/sub system added to the Cloud SDK - see [here](https://github.com/spark/spark-sdk-ios/blob/master/README.md#events-sub-system)

* Continous integration in [Travis-CI](https://travis-ci.org/spark/spark-sdk-ios).

* Unit tests added.

## [0.2.10](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.10) (2015-06-05)

* Add flash files to device API call (flashFiles:)

* Add flash known firmware images to device API call (flashKnownApp:)

* Internal isFlashing timer 

## [0.2.9](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.9) (2015-05-20)

* License fix on podspec

## [0.2.8](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.8) (2015-05-20)

* License updated to Apache 2.0

* Documentation update

## [0.2.7](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.7) (2015-05-12)

* Bug fix bad getDevice API call

## [0.2.6](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.6) (2015-05-06)

* Added device type field to SparkDevice

* Bug fix rename device API call

## [0.2.5](https://github.com/spark/spark-sdk-ios/releases/tag/0.2.5) (2015-05-04)

* Device refresh API call available

* getDevice API call passes access token as URL parameter
