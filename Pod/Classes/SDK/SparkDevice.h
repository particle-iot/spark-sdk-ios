//
//  SparkDevice.h
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
#import "SparkEvent.h"

typedef NS_ENUM(NSInteger, SparkDeviceType) {
    SparkDeviceTypeCore=0,
    SparkDeviceTypePhoton=6,
};

@interface SparkDevice : NSObject

/**
 *  DeviceID string
 */
@property (strong, nonatomic, readonly) NSString* id;
/**
 *  Device name. Device can be renamed in the cloud by setting this property. If renaming fails name will stay the same.
 */
@property (strong, nonatomic) NSString* name;
/**
 *  Is device connected to the cloud?
 */
@property (nonatomic, readonly) BOOL connected;
/**
 *  List of function names exposed by device
 */
@property (strong, nonatomic, readonly) NSArray *functions;
/**
 *  Dictionary of exposed variables on device with their respective types.
 */
@property (strong, nonatomic, readonly) NSDictionary *variables; // @{varName : varType, ...}

@property (strong, nonatomic, readonly) NSString *lastApp;

@property (strong, nonatomic, readonly) NSDate *lastHeard;

@property (nonatomic) BOOL isFlashing;


/**
 *  Device firmware version string
 */
@property (strong, nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) BOOL requiresUpdate;
@property (nonatomic, readonly) SparkDeviceType type; // inactive for now

-(instancetype)initWithParams:(NSDictionary *)params NS_DESIGNATED_INITIALIZER;
-(instancetype)init __attribute__((unavailable("Must use initWithParams:")));

/**
 *  Retrieve a variable value from the device
 *
 *  @param variableName Variable name
 *  @param completion   Completion block to be called when function completes with the variable value retrieved (as id/AnyObject) or NSError object in case on an error
 */
-(void)getVariable:(NSString *)variableName completion:(void(^)(id result, NSError* error))completion;

/**
 *  Call a function on the device
 *
 *  @param functionName Function name
 *  @param args         Array of arguments to pass to the function on the device. Arguments will be converted to string maximum length 63 chars.
 *  @param completion   Completion block will be called when function was invoked on device. First argument of block is the integer return value of the function, second is NSError object in case of an error invoking the function
 */
-(void)callFunction:(NSString *)functionName withArguments:(NSArray *)args completion:(void (^)(NSNumber *, NSError *))completion;

/*
-(void)addEventHandler:(NSString *)eventName handler:(void(^)(void))handler;
-(void)removeEventHandler:(NSString *)eventName;
 */


/**
 *  Request device refresh from cloud
 *  update online status/functions/variables/device name, etc
 *
 *  @param completion Completion block called when function completes with NSError object in case of an error or nil if success.
 *
 */
-(void)refresh:(void(^)(NSError* error))completion;

/**
 *  Remove device from current logged in user account
 *
 *  @param completion Completion block called when function completes with NSError object in case of an error or nil if success.
 */
-(void)unclaim:(void(^)(NSError* error))completion;

/*
-(void)compileAndFlash:(NSString *)sourceCode completion:(void(^)(NSError* error))completion;
-(void)flash:(NSData *)binary completion:(void(^)(NSError* error))completion;
*/

/**
 *  Rename device
 *
 *  @param newName      New device name
 *  @param completion   Completion block called when function completes with NSError object in case of an error or nil if success.
 */
-(void)rename:(NSString *)newName completion:(void(^)(NSError* error))completion;

/**
 *  Flash files to device
 *
 *  @param filesDict    files dictionary in the following format: @{@"filename.bin" : <NSData>, ...} - that is a NSString filename as key and NSData blob as value. More than one file can be flashed. Data is alway binary.
 *  @param completion   Completion block called when function completes with NSError object in case of an error or nil if success. NSError.localized descripion will contain a detailed error report in case of a
 */
-(void)flashFiles:(NSDictionary *)filesDict completion:(void(^)(NSError* error))completion; //@{@"<filename>" : NSData, ...}

/**
 *  Flash known firmware images to device
 *
 *  @param knownAppName    NSString of known app name. Currently @"tinker" is supported. 
 *  @param completion      Completion block called when function completes with NSError object in case of an error or nil if success. NSError.localized descripion will contain a detailed error report in case of a
 */
-(void)flashKnownApp:(NSString *)knownAppName completion:(void (^)(NSError *))completion; // knownAppName = @"tinker", @"blinky", ... see http://docs.

//-(void)compileAndFlashFiles:(NSDictionary *)filesDict completion:(void(^)(NSError* error))completion; //@{@"<filename>" : @"<file contents>"}
//-(void)complileFiles:(NSDictionary *)filesDict completion:(void(^)(NSData *resultBinary, NSError* error))completion; //@{@"<filename>" : @"<file contents>"}

// --------------------------------------------------------------------------------------------------------------------------------------------------------
// Events subsystem:
// --------------------------------------------------------------------------------------------------------------------------------------------------------

/**
 *  Subscribe to events from this specific (claimed) device - both public and private.
 *
 *  @param eventNamePrefix  Filter only events that match name eventNamePrefix, for exact match pass whole string, if nil/empty string is passed any event will trigger eventHandler
 *  @param eventHandler     Event handler function that accepts the event payload dictionary and an NSError object in case of an error
 */
-(id)subscribeToEventsWithPrefix:(NSString *)eventNamePrefix handler:(SparkEventHandler)eventHandler;

/**
 *  Unsubscribe from event/events.
 *
 *  @param eventListenerID The eventListener registration unique ID returned by the subscribe method which you want to cancel
 */
-(void)unsubscribeFromEventWithID:(id)eventListenerID;

@end
