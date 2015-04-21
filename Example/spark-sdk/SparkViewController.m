//
//  SparkViewController.m
//  Spark-SDK
//
//  Created by Ido Kleinman on 03/01/2015.
//  Copyright (c) 2014 Ido Kleinman. All rights reserved.
//

#import "SparkViewController.h"
#import "Spark-SDK.h"

@interface SparkViewController ()

@end

@implementation SparkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testButton:(id)sender {
    [[SparkCloud sharedInstance] loginWithUser:@"ido@spark.io" password:@"<password>" completion:^(NSError *error) {
        [[SparkCloud sharedInstance] getDevices:^(NSArray *sparkDevices, NSError *error) {
            NSLog(@"%@",sparkDevices.description);
        }];
    }];
}

@end
