//
//  SparkDevice.h
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/7/14.
//  Copyright (c) 2014-2015 Spark. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM(NSInteger, SparkDeviceType) {
    SparkDeviceTypeCore=1,
    SparkDeviceTypePhoton,
};

@interface SparkDevice : NSObject

/**
 *  Device ID string
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


/**
 *  Device firmware version string
 */
@property (strong, nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) BOOL requiresUpdate;
//@property (nonatomic, readonly) SparkDeviceType type; // inactive for now

-(instancetype)initWithParams:(NSDictionary *)params NS_DESIGNATED_INITIALIZER;
-(instancetype)init __attribute__((unavailable("Must use initWithParams:")));

/**
 *  Retrieve a variable value from the device
 *
 *  @param variableName Variable name
 *  @param completion   Completion block to be called with the result value or error
 */
-(void)getVariable:(NSString *)variableName completion:(void(^)(id result, NSError* error))completion;

/**
 *  Call a function on the device
 *
 *  @param functionName Function name
 *  @param args         Array of arguments to pass to the function on the device. Arguments will be converted to string maximum length 63 chars.
 *  @param completion   Completion block will be called when function finished running on device. First argument of block is the integer return value of the function, second is NSError object in case of an error invoking the function
 */
-(void)callFunction:(NSString *)functionName withArguments:(NSArray *)args completion:(void (^)(NSNumber *, NSError *))completion;

/*
-(void)addEventHandler:(NSString *)eventName handler:(void(^)(void))handler;
-(void)removeEventHandler:(NSString *)eventName;
 */


// Request device refresh from cloud - update online status/function/variables/name etc
-(void)refresh;

/**
 *  Remove device from current logged in user account
 *
 *  @param completion Completion with NSError object in case of an error. 
 */
-(void)unclaim:(void(^)(NSError* error))completion;

/*
-(void)compileAndFlash:(NSString *)sourceCode completion:(void(^)(NSError* error))completion;
-(void)flash:(NSData *)binary completion:(void(^)(NSError* error))completion;
*/

@end
