//
//  SparkLoginViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkLoginViewController.h"
#import <SparkCloud.h>

@interface SparkLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) LoginCompletion completion;
@property (strong, nonatomic) UIViewController *senderViewController;
@property (strong, nonatomic) SparkCloud *cloud;

@end

@implementation SparkLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cloud = [SparkCloud sharedInstance];
    
    if (self.cloud.loggedInUsername);
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    [self.senderViewController dismissViewControllerAnimated:YES completion:nil];
}

+ (void)presentLoginViewControllerFromViewController:(UIViewController*)sender
                                     withCompletion:(LoginCompletion)completion
{

    UIStoryboard *storyboard = sender.storyboard;
    SparkLoginViewController *slvc = [storyboard instantiateViewControllerWithIdentifier:@"SparkLoginViewController"];
    slvc.completion = [completion copy];
    slvc.senderViewController = sender;
    [sender presentViewController:slvc animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
