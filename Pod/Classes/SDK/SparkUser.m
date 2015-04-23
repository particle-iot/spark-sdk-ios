//
//  SparkUser.m
//  teacup-ios-app
//
//  Created by Ido Kleinman on 1/9/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "SparkUser.h"
#import "KeychainItemWrapper.h"

NSString *const kSparkCredentialsKeychainEntry = @"io.spark.api.Keychain.Credentials";


@interface SparkUser()
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *password;
@end

@implementation SparkUser

-(instancetype)initWithSavedSession
{
    if (self = [super init])
    {
        KeychainItemWrapper *keychainCredentialsItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkCredentialsKeychainEntry accessGroup:nil];
        self.password = [[NSString alloc] initWithData:[keychainCredentialsItem objectForKey:(__bridge id)(kSecValueData)] encoding:NSUTF8StringEncoding];
        self.user = [keychainCredentialsItem objectForKey:(__bridge id)(kSecAttrAccount)];
        
        if ((!self.user) || ([self.user isEqualToString:@""]))
            return nil;
        
        if ((!self.password) || ([self.password isEqualToString:@""]))
            return nil;
        
        return self;
    }
    return nil;
}



-(instancetype)initWithUser:(NSString *)user andPassword:(NSString *)password
{
    if (self = [super init])
    {
        self.user = user;
        self.password = password;
    
        KeychainItemWrapper *keychainCredentialsItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkCredentialsKeychainEntry accessGroup:nil];
        [keychainCredentialsItem setObject:user forKey:(__bridge id)(kSecAttrAccount)];
        [keychainCredentialsItem setObject:password forKey:(__bridge id)(kSecValueData)]; // TODO: debug why this crashes sometimes
        
        return self;
    }
    
    return nil;
}


-(void)removeSession
{
    // remove user
    KeychainItemWrapper *keychainCredentialsItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkCredentialsKeychainEntry accessGroup:nil];
    [keychainCredentialsItem resetKeychainItem];
    self.user = nil;
    self.password = nil;
}

@end
