//
//  Spark-SDK-Tests.m
//  Pods
//
//  Created by Ido on 7/15/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Spark-SDK.h"

@interface Spark_SDK_Tests : XCTestCase

@end

@implementation Spark_SDK_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the ]
    [[SparkCloud sharedInstance] loginWithUser:@"testuser@particle.io" password:@"testuserpass" completion:^(NSError *error) {
        //
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
