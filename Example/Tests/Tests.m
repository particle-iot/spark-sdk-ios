//
//  Tests.m
//  Tests
//
//  Created by Ido on 7/16/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Particle-SDK.h"

#define TEST_USER   @"testuser@particle.io"
#define TEST_PASS   @"testpass"


@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp {
    [super setUp];
    [[ParticleCloud sharedInstance] loginWithUser:@"fsdfds" password:@"fdsfsdf" completion:^(NSError *error) {
        //
    }];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testLoginLogout {
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Login test"];
    [[ParticleCloud sharedInstance] loginWithUser:TEST_USER password:TEST_PASS completion:^(NSError *error) {
        XCTAssertEqualObjects(error, nil, @"Login failed!");
        XCTAssertEqualObjects([ParticleCloud sharedInstance].loggedInUsername, TEST_USER, @"Login user mismatch");
        XCTAssertNotEqualObjects([ParticleCloud sharedInstance].accessToken, nil, @"Session access token missing");
        [[ParticleCloud sharedInstance] logout];
        XCTAssertEqualObjects([ParticleCloud sharedInstance].accessToken, nil, @"Session Access token was not cleared on logout");
        [completionExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


-(void)testGetDevices
{
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Login test"];
    [[ParticleCloud sharedInstance] loginWithUser:TEST_USER password:TEST_PASS completion:^(NSError *error) {
        XCTAssertEqualObjects(error, nil, @"Login failed!");
        XCTAssertEqualObjects([ParticleCloud sharedInstance].loggedInUsername, TEST_USER, @"Login user mismatch");
        [[ParticleCloud sharedInstance] getDevices:^(NSArray *sparkDevices, NSError *error) {
            XCTAssertEqualObjects(error, nil, @"GetDevices call failed");
//            XCTAssertNotEqualObjects(sparkDevices, nil, @"GetDevices returned empty list");
            NSLog(@"%@",sparkDevices.description);
            // do something with test devices
            [completionExpectation fulfill];
            
        }];
        
        
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


/*
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}
*/


@end
