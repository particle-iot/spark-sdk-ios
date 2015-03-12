//
//  SparkViewController.m
//  Spark-SDK
//
//  Created by Ido Kleinman on 03/01/2015.
//  Copyright (c) 2014 Ido Kleinman. All rights reserved.
//

#import "SparkViewController.h"
#import "SparkLoginViewController.h"
#import <SparkCloud.h>

@interface SparkViewController ()
@property (weak, nonatomic) SparkCloud *cloud;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@end

@implementation SparkViewController
//TODO: Make this a table view to display menu options to navigate to.

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.cloud = [SparkCloud sharedInstance];
    self.logoutButton.enabled = NO;
    self.title = @"No User";
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.cloud.isUserLoggedIn) {
        [SparkLoginViewController presentLoginViewControllerFrom:self
                                                  withCompletion:^(SparkLoginViewController *loginViewController, SparkUser *user) {
                                                      [self dismissViewControllerAnimated:YES completion:nil];
                                                      NSLog(@"User: %@", user.user);
                                                  }];
    } else {
        NSLog(@"User: %@ is logged in", self.cloud.loggedInUsername);
        self.logoutButton.enabled = YES;
        self.title = self.cloud.loggedInUsername;
    }
    
}

- (IBAction)logoutButtonPressed:(id)sender {
    [self.cloud logout];
    self.logoutButton.enabled = NO;
    self.title = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
