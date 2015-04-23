//
//  SparkAccessToken.m
//  teacup-ios-app
//
//  Created by Ido Kleinman on 1/5/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "SparkAccessToken.h"
#import "KeychainItemWrapper.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "SparkCloud.h"

NSString *const kSparkAccessTokenKeychainEntry = @"io.spark.api.Keychain.AccessToken";
NSString *const kSparkAccessTokenExpiryDateKey = @"kSparkAccessTokenExpiryDateKey";
NSString *const kSparkAccessTokenStringKey = @"kSparkAccessTokenStringKey";

// how many seconds before expiry date will a token be considered expired (0 = expire on expiry date, 24*60*60 = expire a day before)
#define ACCESS_TOKEN_EXPIRY_MARGIN  0

@interface SparkAccessToken()
@property (nonatomic, strong) NSDate *expiryDate;
@property (nonatomic, strong) NSTimer *expiryTimer;
@property (nonatomic, strong) NSString *accessToken;
@end

@implementation SparkAccessToken

-(instancetype)initWithNewSession:(NSDictionary *)loginResponseDict
{
    self = [super init];
    if (self)
    {
//        NSLog(@"(debug)login responseObject:\n%@",loginResponseDict.description);
        NSNumber *nti = loginResponseDict[@"expires_in"];
        if (!nti) return nil;
        
        self.expiryDate = [[NSDate alloc] initWithTimeIntervalSinceNow:nti.doubleValue];
//        NSLog(@"(debug)access token expiry: %@",self.expiryDate.description);
        self.accessToken = loginResponseDict[@"access_token"];
        if (!self.accessToken)
            return nil;
        
        // verify response object type
        if (![loginResponseDict[@"token_type"] isEqualToString:@"bearer"])
            return nil;

        self.expiryTimer = [[NSTimer alloc] initWithFireDate:self.expiryDate interval:0 target:self selector:@selector(accessTokenExpired:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.expiryTimer forMode:NSDefaultRunLoopMode];

        NSMutableDictionary *accessTokenDict = [NSMutableDictionary new];
        accessTokenDict[kSparkAccessTokenStringKey] = self.accessToken;
        accessTokenDict[kSparkAccessTokenExpiryDateKey] = self.expiryDate;

        NSData *keychainData = [NSKeyedArchiver archivedDataWithRootObject:accessTokenDict];
        KeychainItemWrapper *keychainTokenItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkAccessTokenKeychainEntry accessGroup:nil];
        [keychainTokenItem setObject:keychainData forKey:(__bridge id)(kSecValueData)];
        
        return self;
    }
    
    return nil;
}


-(void)accessTokenExpired:(NSTimer *)timer
{
    [self.expiryTimer invalidate];
    [self.delegate SparkAccessToken:self didExpireAt:self.expiryDate];
}


-(instancetype)initWithSavedSession
{
    self = [super init];
    if (self)
    {
        KeychainItemWrapper *keychainTokenItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkAccessTokenKeychainEntry accessGroup:nil];
        NSData *keychainData = [keychainTokenItem objectForKey:(__bridge id)(kSecValueData)];
        NSDictionary *accessTokenDict;
        if ((keychainData) && (keychainData.length > 0))
        {
            @try {
                // might throw a NSInvalidArgumentException incomprehensible archive for previously incompatible saved sessions
                accessTokenDict = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:keychainData];
            }
            @catch (NSException *exception) {
                // so remove any invalid session data
                [self removeSession];
            }
            
        }
        else
            return nil;
        
        if (accessTokenDict)
        {
            self.accessToken = accessTokenDict[kSparkAccessTokenStringKey];
            self.expiryDate = accessTokenDict[kSparkAccessTokenExpiryDateKey];
        }
        else
            return nil;

        // this also checks if saved session access token has expired already (by getter)
        if (!((self.accessToken) && (self.expiryDate)))
            return nil;
        
        self.expiryTimer = [[NSTimer alloc] initWithFireDate:self.expiryDate interval:0 target:self selector:@selector(accessTokenExpired:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.expiryTimer forMode:NSDefaultRunLoopMode];
        
        return self;
    }
    
    return nil;
}


-(NSString *)accessToken
{
    // always return only a non-expired access token
    NSTimeInterval ti = [self.expiryDate timeIntervalSinceNow];
    if (ti < ACCESS_TOKEN_EXPIRY_MARGIN)
        return nil;
    else
        return _accessToken;
}


-(void)removeSession
{
    KeychainItemWrapper *keychainTokenItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkAccessTokenKeychainEntry accessGroup:nil];
    [keychainTokenItem resetKeychainItem];
    self.accessToken = nil;
}


-(void)dealloc
{
    [self.expiryTimer invalidate];
}

@end
