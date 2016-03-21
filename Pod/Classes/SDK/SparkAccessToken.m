//
//  SparkAccessToken.m
//  teacup-ios-app
//
//  Created by Ido Kleinman on 1/5/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "SparkAccessToken.h"
#import "KeychainItemWrapper.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "SparkCloud.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const kSparkAccessTokenKeychainEntry = @"io.spark.api.Keychain.AccessToken";
NSString *const kSparkAccessTokenExpiryDateKey = @"kSparkAccessTokenExpiryDateKey";
NSString *const kSparkAccessTokenStringKey = @"kSparkAccessTokenStringKey";
NSString *const kSparkRefreshTokenStringKey = @"kSparkRefreshTokenStringKey";


// how many seconds before expiry date will a token be considered expired (0 = expire on expiry date, 24*60*60 = expire a day before)
#define ACCESS_TOKEN_EXPIRY_MARGIN  0

@interface SparkAccessToken()

@property (nonatomic, strong) NSDate *expiryDate;
@property (nonatomic, strong) NSTimer *expiryTimer;
@property (nonatomic, strong, readwrite) NSString *accessToken;
@property (nonatomic, nullable, strong, readwrite) NSString *refreshToken;

@end

@implementation SparkAccessToken

-(nullable instancetype)initWithNewSession:(NSDictionary *)loginResponseDict
{
    self = [super init];
    if (self)
    {
//        NSLog(@"(debug)login responseObject:\n%@",loginResponseDict.description);
        NSNumber *nti = loginResponseDict[@"expires_in"];
        if (!nti) return nil;
        
        if ([nti integerValue]==0)
            self.expiryDate = [NSDate distantFuture];
        else
            self.expiryDate = [[NSDate alloc] initWithTimeIntervalSinceNow:nti.doubleValue];

        self.accessToken = loginResponseDict[@"access_token"];
        if (!self.accessToken)
            return nil;
        
        self.refreshToken = loginResponseDict[@"refresh_token"];
        if (!self.refreshToken)
            return nil;
        
        // verify response object type
        if (![loginResponseDict[@"token_type"] isEqualToString:@"bearer"])
            return nil;

        [self storeSessionInKeychainAndSetExpiryTimer];
        
        return self;
    }
    
    return nil;
}


-(nullable instancetype)initWithToken:(NSString *)token
{
    self = [super init];
    if (self)
    {
        if (!token)
            return nil;
        
        self.accessToken = token;
        self.expiryDate = [NSDate distantFuture];
        self.refreshToken = nil;

        [self storeSessionInKeychainAndSetExpiryTimer];
        
        return self;
    }
    
    return nil;
}

-(void)storeSessionInKeychainAndSetExpiryTimer
{
    if (![self.expiryDate isEqualToDate:[NSDate distantFuture]]) {
        self.expiryTimer = [[NSTimer alloc] initWithFireDate:self.expiryDate interval:0 target:self selector:@selector(accessTokenExpired:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.expiryTimer forMode:NSDefaultRunLoopMode];
    }
    
    NSMutableDictionary *accessTokenDict = [NSMutableDictionary new];
    accessTokenDict[kSparkAccessTokenStringKey] = self.accessToken;
    accessTokenDict[kSparkAccessTokenExpiryDateKey] = self.expiryDate;
    if (self.refreshToken)
        accessTokenDict[kSparkRefreshTokenStringKey] = self.refreshToken;
    
    NSData *keychainData = [NSKeyedArchiver archivedDataWithRootObject:accessTokenDict];
    KeychainItemWrapper *keychainTokenItem = [[KeychainItemWrapper alloc] initWithIdentifier:kSparkAccessTokenKeychainEntry accessGroup:nil];
    [keychainTokenItem setObject:keychainData forKey:(__bridge id)(kSecValueData)];

}



-(nullable instancetype)initWithToken:(NSString *)token andExpiryDate:(NSDate *)expiryDate
{
    self = [super init];
    if (self)
    {
        if (!expiryDate)
            return nil;
        
        if (!token)
            return nil;
        
        self.expiryDate = expiryDate;
        self.accessToken = token;
        self.refreshToken = nil;

        
        [self storeSessionInKeychainAndSetExpiryTimer];
        return self;
    }
    
    return nil;
}

-(nullable instancetype)initWithToken:(NSString *)token withExpiryDate:(NSDate *)expiryDate withRefreshToken:(NSString *)refreshToken
{
    self = [super init];
    if (self)
    {
        if (!expiryDate)
            return nil;
        
        if (!token)
            return nil;
        
        if (!refreshToken)
            return nil;
        
        self.expiryDate = expiryDate;
        self.accessToken = token;
        self.refreshToken = refreshToken;
        
        [self storeSessionInKeychainAndSetExpiryTimer];
        return self;
    }
    
    return nil;
}


-(nullable instancetype)initWithSavedSession
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
            if ([accessTokenDict objectForKey:kSparkAccessTokenExpiryDateKey]) {
                self.expiryDate = accessTokenDict[kSparkAccessTokenExpiryDateKey];
            }
            if ([accessTokenDict objectForKey:kSparkRefreshTokenStringKey]) {
                self.refreshToken = accessTokenDict[kSparkRefreshTokenStringKey];
            } else {
                self.refreshToken = nil;
            }
        }
        else
            return nil;

        // this also checks if saved session access token has expired already (by getter)
        if (!((self.accessToken) && (self.expiryDate)))
            return nil;
        
        if (![self.expiryDate isEqualToDate:[NSDate distantFuture]]) {
            self.expiryTimer = [[NSTimer alloc] initWithFireDate:self.expiryDate interval:0 target:self selector:@selector(accessTokenExpired:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.expiryTimer forMode:NSDefaultRunLoopMode];
        }
        
        return self;
    }
    
    return nil;
}


-(nullable NSString *)accessToken
{
    // always return only a non-expired access token
    if (!self.expiryDate)
        return _accessToken;
    
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

-(void)accessTokenExpired:(NSTimer *)timer
{
    [self.expiryTimer invalidate];
    [self.delegate sparkAccessToken:self didExpireAt:self.expiryDate];
}

-(void)dealloc
{
    [self.expiryTimer invalidate];
}

@end

NS_ASSUME_NONNULL_END
