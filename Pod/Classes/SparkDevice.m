//
//  SparkDevice.m
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/7/14.
//  Copyright (c) 2014-2015 Spark. All rights reserved.
//

#import "SparkDevice.h"
#import "SparkCloud.h"

#define MAX_SPARK_FUNCTION_ARG_LENGTH 63

@interface SparkDevice()
@property (strong, nonatomic) NSString* ID;
@property (nonatomic) BOOL connected; // might be impossible
@property (strong, nonatomic) NSArray *functions;
@property (strong, nonatomic) NSDictionary *variables;
@property (strong, nonatomic) NSString *version;
@property (nonatomic) SparkDeviceType type;
@property (nonatomic) BOOL requiresUpdate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@property (nonatomic, strong) NSURL *baseURL;
@end

@implementation SparkDevice

-(instancetype)initWithParams:(NSDictionary *)params
{
    if (self = [super init])
    {
        self.baseURL = [NSURL URLWithString:kSparkAPIBaseURL];
     
        self.requiresUpdate = NO;
        
        if ([params[@"connected"] boolValue]==YES)
            self.connected = YES;
        else
            self.connected = NO;
        
        self.functions = params[@"functions"];
        self.variables = params[@"variables"];
        
//        self.variables =
        self.ID = params[@"id"];
        self.name = params[@"name"];
        
        if (params[@"cc3000_patch_version"]) // check for other version indication strings - ask doc
        {
            self.type = SparkDeviceTypeCore;
            self.version = (params[@"cc3000_patch_version"]);
        }
        
        if (params[@"device_needs_update"])
        {
            self.requiresUpdate = YES;

        }
        
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];

        if (!self.manager) return nil;
        
        return self;
    }
    
    return nil;
}


-(void)setName:(NSString *)name
{
    // TODO: device renaming code
}

-(void)getVariable:(NSString *)variableName completion:(void(^)(id result, NSError* error))completion
{
    // TODO: check variable name exists in list
    NSURL *url = [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"v1/devices/%@/%@", self.ID, variableName]];
    // TODO: check response of calling a non existant function
    
    [self.manager GET:[url description] parameters:[self defaultParams] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
        {
            NSDictionary *responseDict = responseObject;
            if ([responseDict[@"coreInfo"][@"connected"] boolValue]==NO) // check response
            {
                NSError *err = [self makeErrorWithDescription:@"Device is not connected" code:1001];
                completion(nil,err);
            }
            else
            {
                // check
                completion(responseDict[@"result"],nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (completion)
             completion(nil,error);
     }];

    
}

-(void)callFunction:(NSString *)functionName withArguments:(NSArray *)args completion:(void (^)(NSNumber *, NSError *))completion
{
    // TODO: check function name exists in list
    NSURL *url = [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"v1/devices/%@/%@", self.ID, functionName]];
    
    NSMutableDictionary *params = [self defaultParams];
    // TODO: check response of calling a non existant function
    
    if (args) {
        NSMutableArray *argsStr = [[NSMutableArray alloc] initWithCapacity:args.count];
        for (id arg in args)
        {
            [argsStr addObject:[arg description]];
        }
        NSString *argsValue = [argsStr componentsJoinedByString:@","];
        if (argsValue.length > MAX_SPARK_FUNCTION_ARG_LENGTH)
        {
            // TODO: arrange user error/codes in a list
            NSError *err = [self makeErrorWithDescription:[NSString stringWithFormat:@"Maximum argument length cannot exceed %d",MAX_SPARK_FUNCTION_ARG_LENGTH] code:1000];
            if (completion)
                completion(nil,err);
            return;
        }
            
        params[@"args"] = argsValue;
    }
    
    
    [self.manager POST:[url description] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
        {
            NSDictionary *responseDict = responseObject;
            if ([responseDict[@"connected"] boolValue]==NO)
            {
                NSError *err = [self makeErrorWithDescription:@"Device is not connected" code:1001];
                completion(nil,err);
            }
            else
            {
                // check
                NSNumber *result = responseDict[@"return_value"];
                completion(result,nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        if (completion)
            completion(nil,error);
    }];
    
}



-(void)unclaim:(void (^)(NSError *))completion
{

    NSURL *url = [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"v1/devices/%@", self.ID]];

    NSMutableDictionary *params = [self defaultParams];
    params[@"id"] = self.ID;
    
    [self.manager DELETE:[url description] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
        {
            NSDictionary *responseDict = responseObject;
            if ([responseDict[@"ok"] boolValue])
                completion(nil);
            else
                completion([self makeErrorWithDescription:@"Could not unclaim device" code:1003]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (completion)
             completion(error);
     }];
    

}


#pragma mark Internal use methods
- (NSMutableDictionary *)defaultParams
{
    if ([SparkCloud sharedInstance].accessToken)
    {
        return [@{@"access_token" : [SparkCloud sharedInstance].accessToken} mutableCopy];
    }
    else return nil;
}


-(NSError *)makeErrorWithDescription:(NSString *)desc code:(NSInteger)errorCode
{
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"SparkAPIError" code:errorCode userInfo:errorDetail];
}



-(NSString *)description
{
    NSString *desc = [NSString stringWithFormat:@"Spark Device\nType: %@\nID: %@\nName: %@\nConnected: %@\nVariables: %@\nFunctions: %@\nVersion: %@\nRequires update: %@\n",
                      (self.type == SparkDeviceTypeCore) ? @"Spark Core" : @"Spark Photon",
                      self.ID,
                      self.name,
                      (self.connected) ? @"True" : @"False",
                      [self.variables description], [self.functions description], self.version,
                      (self.requiresUpdate) ? @"True" : @"False"];
    
    return desc;
    
}


@end
