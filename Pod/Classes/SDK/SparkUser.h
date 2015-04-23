//
//  SparkUser.h
//  teacup-ios-app
//
//  Created by Ido Kleinman on 1/9/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SparkUser : NSObject
/**
 *  User name, should be a valid email address
 */
@property (nonatomic, strong, readonly) NSString *user;

/**
 *  Password string
 */
@property (nonatomic, strong, readonly) NSString *password;

/**
 *  Initialize SparkUser class with new credentials and store session in keychain
 *
 *  @param user     New username credential
 *  @param password New password credential
 *
 *  @return SparkUser instance
 */
-(instancetype)initWithUser:(NSString *)user andPassword:(NSString *)password;

/**
 *  Try to initialize a SparkUser class with stored keychain session
 *
 *  @return SparkUser instance if successfully retrieved session from keychain, nil if failed
 */
-(instancetype)initWithSavedSession;

-(instancetype)init __attribute__((unavailable("Must use -initWithUser: or -initWithSavedSession:")));

/**
 *  Remove user credentials session data from keychain
 */
-(void)removeSession;

@end
