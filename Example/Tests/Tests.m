//
//  Tests.m
//  Tests
//
//  Created by Ido on 7/16/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Spark-SDK.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp {
    [super setUp];
    [[SparkCloud sharedInstance] loginWithUser:@"fsdfds" password:@"fdsfsdf" completion:^(NSError *error) {
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

- (void)testLogin {
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Login test"];
    [[SparkCloud sharedInstance] loginWithUser:@"ido@spark.io" password:@"test123" completion:^(NSError *error) {
        XCTAssertEqualObjects(error, nil, @"Login failed!");
        [completionExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
