//
//  SparkAccessToken.h
//  teacup-ios-app
//
//  Created by Ido Kleinman on 1/5/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SparkAccessToken;

@protocol SparkAccessTokenDelegate <NSObject>
-(void)SparkAccessToken:(SparkAccessToken *)accessToken didExpireAt:(NSDate *)date;
@end

@interface SparkAccessToken : NSObject
/**
 *  Access token string to be used when calling cloud API
 */
@property (nonatomic, strong, readonly) NSString *accessToken;
/**
 *  Delegate to receive didExpireAt method call whenever a token is detected as expired
 */
@property (nonatomic, weak) id<SparkAccessTokenDelegate> delegate;

/**
 *  Initialze SparkAccessToken class with new session
 *
 *  @param loginResponseDict response object from Spark cloud login deserialized as NSDictionary
 *
 *  @return New SparkAccessToken instance
 */
-(instancetype)initWithNewSession:(NSDictionary *)loginResponseDict;

/**
 *  Initialize SparkAccessToken from existing session stored in keychain
 *
 *  @return A SparkAccessToken instance in case session is stored in keychain and token has not expired, nil if not
 */
-(instancetype)initWithSavedSession;

-(instancetype)init __attribute__((unavailable("Must use initWithNewSession: or initWithSavedSession:")));

/**
 *  Remove access token session data from keychain
 */
-(void)removeSession;

@end
