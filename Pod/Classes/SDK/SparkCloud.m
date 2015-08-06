//
//  SparkCloud.m
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/7/14.
//  Copyright (c) 2014-2015 Spark. All rights reserved.
//

#import "SparkCloud.h"
#import "KeychainItemWrapper.h"
#import "SparkAccessToken.h"
#import "SparkUser.h"
#import <AFNetworking/AFNetworking.h>
#import <EventSource.h>
#import "SparkEvent.h"


#define GLOBAL_API_TIMEOUT_INTERVAL     31.0f


NSString *const kSparkAPIBaseURL = @"https://api.particle.io";

NSString *const kEventListenersDictEventSourceKey = @"eventSource";
NSString *const kEventListenersDictHandlerKey = @"eventHandler";
NSString *const kEventListenersDictIDKey = @"id";

@interface SparkCloud () <SparkAccessTokenDelegate>
@property (nonatomic, strong) NSURL* baseURL;
@property (nonatomic, strong) SparkAccessToken* token;
@property (nonatomic, strong) SparkUser* user;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@property (nonatomic, strong) NSMutableDictionary *eventListenersDict;
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
        
        // init event listeners internal dictionary
        self.eventListenersDict = [NSMutableDictionary new];
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

-(BOOL)isLoggedIn
{
    return (self.loggedInUsername != nil);
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
    
//    NSDictionary *OAuthClientCredentialsDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"OAuthClientCredentials" ofType:@"plist"]];
//    NSString *clientId = OAuthClientCredentialsDict[@"clientId"];
//    NSString *clientSecret = OAuthClientCredentialsDict[@"clientSecret"];
    
    if (!self.OAuthClientId)
        self.OAuthClientId = @"particle";
    if (!self.OAuthClientSecret)
        self.OAuthClientSecret = @"particle";
    
    
    [self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.OAuthClientId password:self.OAuthClientSecret];
    // OAuth login
    [self.manager POST:@"oauth/token" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *responseDict = responseObject;

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
                 NSString *errorString;
                 if (responseDict[@"errors"][0])
                     errorString = [NSString stringWithFormat:@"Could not sign up: %@",responseDict[@"errors"][0]];
                 else
                     errorString = @"Error signing up";
                 completion([self makeErrorWithDescription:errorString code:1004]);
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


-(void)signupWithCustomer:(NSString *)email password:(NSString *)password orgSlug:(NSString *)orgSlug completion:(void (^)(NSError *))completion
{
    if (!orgSlug)
        completion([self makeErrorWithDescription:@"Organization slug not specified" code:1006]);

    // non default params
    NSMutableDictionary *params = [@{
                             @"email": email,
                             @"password": password,
                             } mutableCopy];
    
//    if (inviteCode)
//        params[@"activation_code"] = inviteCode;
    
    NSString *url = [NSString stringWithFormat:@"/v1/orgs/%@/customers",orgSlug];
    
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
    [self.token removeSession];
    [self.user removeSession];
}


-(void)claimDevice:(NSString *)deviceID completion:(void (^)(NSError *))completion
{
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];

    NSMutableDictionary *params = [NSMutableDictionary new]; //[self defaultParams];
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
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];

    NSString *urlPath = [NSString stringWithFormat:@"/v1/devices/%@",deviceID];
    [self.manager GET:urlPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
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


-(void)getDevices:(void (^)(NSArray *sparkDevices, NSError *error))completion
{
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];
    
    [self.manager GET:@"/v1/devices" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (completion)
         {
             
             NSArray *responseList = responseObject;
             NSMutableArray *queryDeviceIDList = [[NSMutableArray alloc] init];
             __block NSMutableArray *deviceList = [[NSMutableArray alloc] init];
             __block NSError *deviceError = nil;
             // analyze
             for (NSDictionary *deviceDict in responseList)
             {
                 if (deviceDict[@"id"])   // ignore <null> device listings that sometimes return from /v1/devices API call
                 {
                     if (![deviceDict[@"id"] isKindOfClass:[NSNull class]])
                     {
                         if ([deviceDict[@"connected"] boolValue]==YES) // do inquiry only for online devices (otherwise we waste time on request timeouts and get no new info)
                         {
                             // if it's online then add it to the query list so we can get additional information about it
                             [queryDeviceIDList addObject:deviceDict[@"id"]];
                         }
                         else
                         {
                             // if it's offline just make an instance for it with the limited data with have
                             SparkDevice *device = [[SparkDevice alloc] initWithParams:deviceDict];
                             [deviceList addObject:device];
                         }
                     }
                     
                 }
             }
             
             // iterate thru deviceList and create SparkDevice instances through query
             __block dispatch_group_t group = dispatch_group_create();
             
             for (NSString *deviceID in queryDeviceIDList)
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
                     if (deviceError && (deviceList.count==0)) // empty list? error? report it
                         completion(nil, deviceError);
                     else if (deviceList.count > 0)  // if some devices reported error but some not, then return at least the ones that didn't report error, ditch error
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



-(void)generateClaimCode:(void(^)(NSString *claimCode, NSArray *userClaimedDeviceIDs, NSError *error))completion;
{
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];

    NSString *urlPath = [NSString stringWithFormat:@"/v1/device_claims"];
     [self.manager POST:urlPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
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
    
}



-(void)generateClaimCodeForOrganization:(NSString *)orgSlug andProduct:(NSString *)productSlug withActivationCode:(NSString *)activationCode completion:(void(^)(NSString *claimCode, NSArray *userClaimedDeviceIDs, NSError *error))completion;
{
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];

    
    NSDictionary *params;
    if (activationCode)
        params = @{@"activation_code" : activationCode};

    
    NSString *urlPath = [NSString stringWithFormat:@"/v1/orgs/%@/products/%@/device_claims",orgSlug,productSlug];
    [self.manager POST:urlPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
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
                 completion(nil, nil, [self makeErrorWithDescription:@"Could not generate a claim code" code:1007]);
             }
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (completion)
             completion(nil, nil, [NSError errorWithDomain:error.domain code:operation.response.statusCode userInfo:error.userInfo]);
         NSLog(@"generateClaimCodeOrganization %@ Error: %@", urlPath, error.localizedDescription);
     }];
    
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
         NSLog(@"requestPasswordReset Error %ld: %@", (long)operation.response.statusCode, error.localizedDescription);
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
        NSLog(@"listTokens %@",[error localizedDescription]);
    }];
    [self.manager.requestSerializer clearAuthorizationHeader];
    
}

/*
- (NSMutableDictionary *)defaultParams
{
    // Access token in HTTP body
    if (self.token)
        return [@{@"access_token": self.token.accessToken} mutableCopy];
    else
        return nil;
}
*/

-(NSError *)makeErrorWithDescription:(NSString *)desc code:(NSInteger)errorCode
{
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"SparkAPIError" code:errorCode userInfo:errorDetail];
}



#pragma mark Events subsystem implementation
-(id)subscribeToEventWithURL:(NSURL *)url handler:(SparkEventHandler)eventHandler
{
    if (!self.accessToken)
    {
        eventHandler(nil, [self makeErrorWithDescription:@"No active access token" code:1008]);
        return nil;
    }

    // TODO: add eventHandler + source to an internal dictionary so it will be removeable later by calling removeEventListener on saved Source
    EventSource *source = [EventSource eventSourceWithURL:url timeoutInterval:30.0f queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) accessToken:self.accessToken];
    
    //    if (eventName == nil)
    //        eventName = @"no_name";
    
    // - event example -
    // event: Temp
    // data: {"data":"Temp1 is 41.900002 F, Temp2 is $f F","ttl":"60","published_at":"2015-01-13T01:23:12.269Z","coreid":"53ff6e066667574824151267"}
    
    //    [source addEventListener:@"" handler:^(Event *event) { //event name
//    [source onMessage:
    
     EventSourceEventHandler handler = ^void(Event *event) {
        if (eventHandler)
        {
            if (event.error)
                eventHandler(nil, event.error);
            else
            {
                // deserialize event payload into dictionary
                NSError *error;
                NSDictionary *jsonDict;
                NSMutableDictionary *eventDict;
                if (event.data)
                {
                    jsonDict = [NSJSONSerialization JSONObjectWithData:event.data options:0 error:&error];
                    eventDict = [jsonDict mutableCopy];
                }
                
                if ((eventDict) && (!error))
                {
                    if (event.name)
                    {
                        eventDict[@"event"] = event.name; // add event name to dict
                    }
                    SparkEvent *sparkEvent = [[SparkEvent alloc] initWithEventDict:eventDict];
                    eventHandler(sparkEvent ,nil); // callback with parsed data
                }
                else if (error)
                {
                    eventHandler(nil, error);
                }
            }
        }
        
    };
    
    [source onMessage:handler]; // bind the handler
    
    id eventListenerID = [NSUUID UUID]; // create the eventListenerID
    self.eventListenersDict[eventListenerID] = @{kEventListenersDictHandlerKey : handler,
                                                 kEventListenersDictEventSourceKey : source}; // save it in the internal dictionary for future unsubscribing
    
    return eventListenerID;
    
}


-(void)unsubscribeFromEventWithID:(id)eventListenerID
{
    NSDictionary *eventListenerDict = [self.eventListenersDict objectForKey:eventListenerID];
    if (eventListenerDict)
    {
        EventSource *source = [eventListenerDict objectForKey:kEventListenersDictEventSourceKey];
        EventSourceEventHandler handler = [eventListenerDict objectForKey:kEventListenersDictHandlerKey];
        [source removeEventListener:MessageEvent handler:handler];
        [self.eventListenersDict removeObjectForKey:eventListenerID];
    }
}


-(id)subscribeToAllEventsWithPrefix:(NSString *)eventNamePrefix handler:(SparkEventHandler)eventHandler
{
    // GET /v1/events[/:event_name]
    NSString *endpoint;
    if ((!eventNamePrefix) || [eventNamePrefix isEqualToString:@""])
    {
        endpoint = [NSString stringWithFormat:@"%@/v1/events", self.baseURL];
    }
    else
    {
        endpoint = [NSString stringWithFormat:@"%@/v1/events/%@", self.baseURL, eventNamePrefix];
    }
    
    return [self subscribeToEventWithURL:[NSURL URLWithString:endpoint] handler:eventHandler];
}


-(id)subscribeToMyDevicesEventsWithPrefix:(NSString *)eventNamePrefix handler:(SparkEventHandler)eventHandler
{
    // GET /v1/devices/events[/:event_name]
    NSString *endpoint;
    if ((!eventNamePrefix) || [eventNamePrefix isEqualToString:@""])
    {
        // TODO: check
        endpoint = [NSString stringWithFormat:@"%@/v1/devices/events", self.baseURL];
    }
    else
    {
        endpoint = [NSString stringWithFormat:@"%@/v1/devices/events/%@", self.baseURL, eventNamePrefix];
    }
    
    return [self subscribeToEventWithURL:[NSURL URLWithString:endpoint] handler:eventHandler];
    
}

-(id)subscribeToDeviceEventsWithPrefix:(NSString *)eventNamePrefix deviceID:(NSString *)deviceID handler:(SparkEventHandler)eventHandler
{
    // GET /v1/devices/:device_id/events[/:event_name]
    NSString *endpoint;
    if ((!eventNamePrefix) || [eventNamePrefix isEqualToString:@""])
    {
        // TODO: check
        endpoint = [NSString stringWithFormat:@"%@/v1/devices/%@/events", self.baseURL,deviceID];
    }
    else
    {
        endpoint = [NSString stringWithFormat:@"%@/v1/devices/%@/events/%@", self.baseURL, deviceID, eventNamePrefix];
    }
    
    return [self subscribeToEventWithURL:[NSURL URLWithString:endpoint] handler:eventHandler];
}



-(void)publishEventWithName:(NSString *)eventName data:(NSString *)data isPrivate:(BOOL)isPrivate ttl:(NSUInteger)ttl completion:(void (^)(NSError *))completion
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",self.token.accessToken];
    [self.manager.requestSerializer setValue:authorization forHTTPHeaderField:@"Authorization"];
    
    params[@"name"]=eventName;
    params[@"data"]=data;
    if (isPrivate)
        params[@"private"]=@"true";
    else
        params[@"private"]=@"false"; // TODO: check if needed
    
    params[@"ttl"] = [NSString stringWithFormat:@"%lu", (unsigned long)ttl];
    
    [self.manager POST:@"/v1/devices/events" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
        {
            // TODO: check server response for that
            NSDictionary *responseDict = responseObject;
           if ([responseDict[@"ok"] boolValue]==NO)
            {
                NSError *err = [self makeErrorWithDescription:@"Server reported error publishing event" code:1009]; 
                completion(err);
            }
            else
            {
                completion(nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (completion)
             completion(error);
     }];
    
    
    
}

@end
