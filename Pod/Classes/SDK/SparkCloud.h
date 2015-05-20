//
//  SparkCloud.h
//  Particle iOS Cloud SDK
//
//  Created by Ido Kleinman
//  Copyright 2015 Particle
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Foundation/Foundation.h>
#import "SparkDevice.h"

extern NSString *const kSparkAPIBaseURL;

@interface SparkCloud : NSObject

/**
 *  Currently loggeed in user name, nil if no session exists
 */
@property (nonatomic, strong, readonly) NSString* loggedInUsername;
/**
 *  Current session access token string
 */
@property (nonatomic, strong, readonly) NSString *accessToken;


/**
 *  Singleton instance of SparkCloud class
 *
 *  @return SparkCloud
 */
+ (instancetype)sharedInstance;

/**
 *  Login with existing account credentials to Spark cloud
 *
 *  @param user       User name, must be a valid email address
 *  @param password   Password
 *  @param completion Completion block will be called when login finished, NSError object will be passed in case of an error, nil if success
 */
-(void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(NSError *error))completion;

/**
 *  Sign up with new account credentials to Spark cloud
 *
 *  @param user       Required user name, must be a valid email address
 *  @param password   Required password
 *  @param completion Completion block will be called when sign-up finished, NSError object will be passed in case of an error, nil if success
 */
-(void)signupWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(NSError *error))completion;


/**
 *  Sign up with new account credentials to Spark cloud
 *
 *  @param email      Required user name, must be a valid email address
 *  @param password   Required password
 *  @param inviteCode Optional invite code for opening an account
 *  @param orgName    Organization name to include in cloud API endpoint URL
 *  @param completion Completion block will be called when sign-up finished, NSError object will be passed in case of an error, nil if success
 */
-(void)signupWithOrganizationalUser:(NSString *)email password:(NSString *)password inviteCode:(NSString *)inviteCode orgName:(NSString *)orgName completion:(void (^)(NSError *))completion;

/**
 *  Logout user, remove session data
 */
-(void)logout;


/**
 *  Get an array of instances of all user's claimed devices
 *  offline devices will contain only partial data (no info about functions/variables)
 *
 *  @param completion Completion block with the device instances array in case of success or with NSError object if failure
 */
-(void)getDevices:(void (^)(NSArray *sparkDevices, NSError *error))completion;

/**
 *  Get a specific device instance by its deviceID. If the device is offline the instance will contain only partial information the cloud has cached, 
 *  notice that the the request might also take quite some time to complete for offline devices.
 *
 *  @param deviceID   required deviceID
 *  @param completion Completion block with first arguemnt as the device instance in case of success or with second argument NSError object if operation failed
 */
-(void)getDevice:(NSString *)deviceID completion:(void (^)(SparkDevice *, NSError *))completion;

// Not available yet
//-(void)publishEvent:(NSString *)eventName data:(NSData *)data;

/**
 *  Claim the specified device to the currently logged in user (without claim code mechanism)
 *
 *  @param deviceID   required deviceID
 *  @param completion Completion block with NSError object if failure, nil if success
 */
-(void)claimDevice:(NSString *)deviceID completion:(void(^)(NSError *))completion;

/**
 *  Get a short-lived claiming token for transmitting to soon-to-be-claimed device in soft AP setup process
 *
 *  @param completion Completion block with claimCode string returned (48 random bytes base64 encoded to 64 ASCII characters), second argument is a list of the devices currently claimed by current session user and third is NSError object for failure, nil if success
 */

-(void)generateClaimCode:(void(^)(NSString *claimCode, NSArray *userClaimedDeviceIDs, NSError *error))completion;

/**
 *  Request password reset for user 
 *  command generates confirmation token and sends email to customer using org SMTP settings
 *
 *  @param email      user email
 *  @param completion Completion block with NSError object if failure, nil if success
 */
-(void)requestPasswordReset:(NSString *)orgName email:(NSString *)email completion:(void(^)(NSError *))completion;


@end
