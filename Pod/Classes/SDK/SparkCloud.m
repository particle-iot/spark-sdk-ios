//
//  SparkCloud.m
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/7/14.
//  Copyright (c) 2014-2015 Spark. All rights reserved.
//

#import "SparkCloud.h"
#import "../Helpers/KeychainItemWrapper.h"
#import "SparkAccessToken.h"
#import "SparkUser.h"
//#import "SparkSetupCustomization.h"

#define GLOBAL_API_TIMEOUT_INTERVAL     7.0f


//#define PRODUCTION
//#define STAGING
#define IFTTT

#ifdef STAGING
NSString *const kSparkAPIBaseURL = @"https://staging-api.spark.io"; //@"https://api.spark.io";
#endif

#ifdef PRODUCTION
NSString *const kSparkAPIBaseURL = @"https://api.spark.io";
#endif

#ifdef IFTTT
NSString *const kSparkAPIBaseURL = @"https://ifttt-api.spark.io";
#endif


@interface SparkCloud () <SparkAccessTokenDelegate>
@property (nonatomic, strong) NSURL* baseURL;
@property (nonatomic, strong) SparkAccessToken* token;
@property (nonatomic, strong) SparkUser* user;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@end


@implementation SparkCloud

#pragma mark Class initialization and singleton instancing

+ (instancetype)sharedInstance;
{
    // TODO: no singleton, initializer gets: CloudConnection, CloudEndpoint (URL) to allow private cloud, dependency injection
    static SparkCloud *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.baseURL = [NSURL URLWithString:kSparkAPIBaseURL];
//        self.loggedIn = NO;

        // try to restore session (user and access token)
        self.user = [[SparkUser alloc] initWithSavedSession];
        self.token = [[SparkAccessToken alloc] initWithSavedSession];
        if (self.token)
            self.token.delegate = self;
        
        // Init HTTP manager
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [self.manager.requestSerializer setTimeoutInterval:GLOBAL_API_TIMEOUT_INTERVAL];
        
        if (!self.manager)
            return nil;
    }
    return self;
}


#pragma mark Getter functions
-(NSString *)accessToken
{
    if (self.token)
        return self.token.accessToken;
    else
        return nil;
}


-(NSString *)loggedInUsername
{
    if ((self.user) && (self.token))
        return self.user.user;
    else
        return nil;
}

#pragma mark Delegate functions
-(void)SparkAccessToken:(SparkAccessToken *)accessToken didExpireAt:(NSDate *)date
{
    // handle auto-renewal of expired access tokens by internal timer event
    if (self.user)
    {
        [self loginWithUser:self.user.user password:self.user.password completion:nil];
    }
    else
    {
        self.token = nil;
    }
}


#pragma mark SDK public functions
-(void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(NSError *error))completion
{
    // non default params
    NSDictionary *params = @{
                             @"grant_type": @"password",
                             @"username": user,
                             @"password": password,
                             };
    
    // auth header can contain any user:pass
//  STAGING:
//     "id": "keurig-ios-app-6378",
//     "secret": "b5c943c329361994fcc4b7e64e53438bf78c44c0"
//    PRODUCTION
//    "id": "keurig-ios-app-1225",
//    "secret": "e57d624245fbe11829c42efc946465c1b7740949"

    
    NSString *clientId, *clientSecret;
    

#if defined(STAGING)
    clientId = @"keurig-ios-app-6378";
    clientSecret = @"b5c943c329361994fcc4b7e64e53438bf78c44c0";
#else
    clientId = @"keurig-ios-app-1225";
    clientSecret = @"e57d624245fbe11829c42efc946465c1b7740949";
#endif
    
//    [self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"spark" password:@"spark"];
    
    [self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:clientId password:clientSecret];
    // OAuth login
    [self.manager POST:@"oauth/token" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *responseDict = responseObject;
//        NSLog(@"Login with %@:%@ success, got new token %@",user,password,responseDict.description);

        self.token = [[SparkAccessToken alloc] initWithNewSession:responseDict];
        if (self.token) // login was successful
        {
            self.token.delegate = self;
            self.user = [[SparkUser alloc] initWithUser:user andPassword:password];
        }
        
        if (completion)
        {
            completion(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // check type of error?
        if (completion)
            completion([NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [self.manager.requestSerializer clearAuthorizationHeader];
}



-(void)signupWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(NSError *))completion
{
    // non default params
    NSDictionary *params = @{
                             @"username": user,
                             @"password": password,
                             };
    
    [self.manager POST:@"/v1/users" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *responseDict = responseObject;
         if (completion) {
             if ([responseDict[@"ok"] boolValue])
             {
                 completion(nil);
             }
             else
             {
                 completion([self makeErrorWithDescription:@"Could not sign up" code:1004]);
             }
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         // check type of error?
         if (completion)
             completion([NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
         NSLog(@"Error: %@", error.localizedDescription);
     }];
    
    [self.manager.requestSerializer clearAuthorizationHeader];
}


// TODO: fix according to spec
// spec: https://github.com/spark/rfcs/blob/feature/product-users/services/product-users.md
// and: https://github.com/spark/rfcs/issues/15
-(void)signupWithOrganizationalUser:(NSString *)email password:(NSString *)password inviteCode:(NSString *)inviteCode orgName:(NSString *)orgName completion:(void (^)(NSError *))completion
{
    if (!orgName)
        completion([self makeErrorWithDescription:@"Organization not specified" code:1006]);

    // non default params
    NSMutableDictionary *params = [@{
                             @"email": email,
                             @"password": password,
                             } mutableCopy];
    
    if (inviteCode)
        params[@"activation_code"] = inviteCode;
                    
    NSString *url = [NSString stringWithFormat:@"/v1/orgs/%@/customers",orgName];
    
    [self.manager POST:url parameters:[params copy] success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *responseDict = responseObject;
         if (completion) {
             if (operation.response.statusCode == 201)
             {
                 completion(nil);
             }
             else
             {
                 NSString *errorDesc = ([responseDict[@"error"] stringValue]); // check name of field
                 completion([self makeErrorWithDescription:errorDesc code:1004]);
             }
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         // check type of error?
         if (completion)
             completion([NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
         
         NSLog(@"Error %ld: %@", (long)operation.response.statusCode, error.localizedDescription);
     }];
    
    [self.manager.requestSerializer clearAuthorizationHeader];
}





-(void)logout
{
    [SparkAccessToken removeSession];
    [SparkUser removeSession];
}


-(void)claimDevice:(NSString *)deviceID completion:(void (^)(NSError *))completion
{
    NSMutableDictionary *params = [self defaultParams];
    params[@"id"] = deviceID;
    [self.manager POST:@"/v1/devices" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion)
         {
             NSMutableDictionary *responseDict = responseObject;

             if ([responseDict[@"ok"] boolValue])
                 completion(nil);
             else
                 completion([self makeErrorWithDescription:@"Could not claim device" code:1002]);
                 
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         // check type of error?
         if (completion)
             completion([NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
     }];
    

}

-(void)getDevice:(NSString *)deviceID completion:(void (^)(SparkDevice *, NSError *))completion
{
    NSString *urlPath = [NSString stringWithFormat:@"/v1/devices/%@",deviceID];
    [self.manager GET:urlPath parameters:[self defaultParams] success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion)
         {
             NSMutableDictionary *responseDict = responseObject;
//             responseDict[@"access_token"] = self.accessToken; // add access token 
             
             SparkDevice *device = [[SparkDevice alloc] initWithParams:responseDict];
             if (completion)
                completion(device, nil);
             
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         // check type of error?
         if (completion)
             completion(nil, [NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
//         NSLog(@"Error: %@", error.localizedDescription);
     }];
  
}




-(void)getDevices:(void (^)(NSArray *devices, NSError *error))completion
{
     [self.manager GET:@"/v1/devices" parameters:[self defaultParams] success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion)
         {
             
             NSArray *responseList = responseObject;
             NSMutableArray *deviceIDList = [[NSMutableArray alloc] initWithCapacity:responseList.count];
             __block NSMutableArray *deviceList = [[NSMutableArray alloc] initWithCapacity:responseList.count];
             __block NSError *deviceError = nil;
             // analyze
             for (NSDictionary *deviceDict in responseList)
             {
                 [deviceIDList addObject:deviceDict[@"id"]];
             }

             // iterate thru deviceList and create SparkDevice instances through query
             __block dispatch_group_t group = dispatch_group_create();
             
             for (NSString *deviceID in deviceIDList)
             {
                 dispatch_group_enter(group);
                 [self getDevice:deviceID completion:^(SparkDevice *device, NSError *error) {
                     if ((!error) && (device))
                         [deviceList addObject:device];
                     
                     if ((error) && (!deviceError)) // if there wasn't an error before cache it
                         deviceError = error;
                     
                     dispatch_group_leave(group);
                 }];
             }
             
             // call user's completion block on main thread after all concurrent GET requests finished and SparkDevice instances created
             dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                 if (completion)
                 {
                     if (deviceError)
                         completion(nil, deviceError);
                     else if (deviceList.count > 0)
                         completion(deviceList, nil);
                     else
                         completion(nil, nil);
                 }
             });
             
             
             
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         // check type of error?
         if (completion)
             completion(nil, [NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
//         NSLog(@"Error: %@", error.localizedDescription);
     }];
}



//-(void)generateClaimCode:(void (^)(NSString *, NSArray *, NSError *))completion
-(void)generateClaimCode:(NSString *)orgName completion:(void (^)(NSString *, NSArray *, NSError *))completion
{

    NSString *urlPath = [NSString stringWithFormat:@"/v1/orgs/%@/device_claims",orgName]; // TODO: DEBUG - orgname should not be a part of this
//    urlPath = @"/v1/orgs/keurig/device_claims"; // DEBUG
     [self.manager POST:urlPath parameters:[self defaultParams] success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion)
         {
             NSDictionary *responseDict = responseObject;
             if (responseDict[@"claim_code"])
             {
                 NSArray *claimedDeviceIDs = responseDict[@"device_ids"];
                 if ((claimedDeviceIDs) && (claimedDeviceIDs.count > 0))
                 {
                     completion(responseDict[@"claim_code"], responseDict[@"device_ids"], nil);
                 }
                 else
                 {
                     completion(responseDict[@"claim_code"], nil, nil);
                 }
             }
             else
             {
                 completion(nil, nil, [self makeErrorWithDescription:@"Could not generate a claim code" code:1005]); //TODO: collect all codes to a table
             }
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (completion)
             completion(nil, nil, [NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
         NSLog(@"generateClaimCode %@ Error: %@", urlPath, error.localizedDescription);
     }];
    
//    [self.manager.requestSerializer clearAuthorizationHeader];
    
}


//-(void)requestPasswordReset:(NSString *)email completion:(void (^)(NSError *))completion
-(void)requestPasswordReset:(NSString *)orgName email:(NSString *)email completion:(void (^)(NSError *))completion
{
    NSDictionary *params = @{@"email": email};
    NSString *urlPath = [NSString stringWithFormat:@"/v1/orgs/%@/customers/reset_password",orgName]; // TODO: DEBUG - orgname should not be a part of this

    [self.manager POST:urlPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion) // TODO: check responses
         {
             completion(nil);
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (completion)
         {
            // make error have the HTTP response status code
             // TODO: for all
             completion([NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
         }
         NSLog(@"Error %ld: %@", (long)operation.response.statusCode, error.localizedDescription);
     }];
    
}





#pragma mark Internal use methods
-(void)listTokens:(NSString *)user password:(NSString *)password
{
    [self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    [self.manager GET:@"/v1/access_tokens" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *responseArr = responseObject;
                NSLog(@"(debug) listTokens:\n%@",[responseArr description]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        NSLog(@"%@",[error localizedDescription]);
    }];
    [self.manager.requestSerializer clearAuthorizationHeader];
    
}


- (NSMutableDictionary *)defaultParams
{
    if (self.token)
        return [@{@"access_token": self.token.accessToken} mutableCopy];
    else
        return nil;
}


-(NSError *)makeErrorWithDescription:(NSString *)desc code:(NSInteger)errorCode
{
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"SparkAPIError" code:errorCode userInfo:errorDetail];
}





@end
