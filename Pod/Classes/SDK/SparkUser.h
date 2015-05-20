//
//  SparkUser.h
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
