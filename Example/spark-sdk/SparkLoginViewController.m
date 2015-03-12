//
//  SparkLoginViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkLoginViewController.h"
#import <SparkCloud.h>
#import <SVProgressHUD.h>

@interface SparkLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) LoginCompletion completion;
@property (strong, nonatomic) UIViewController *senderViewController;
@property (weak, nonatomic) SparkCloud *cloud;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *validationMessageLabel;
@property (strong, nonatomic) NSString *validationMessage;

@end

@implementation SparkLoginViewController
@synthesize validationMessage = _validationMessage;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cloud = [SparkCloud sharedInstance];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    
    if (self.usernameTextField.text.length<=0 || self.passwordTextField.text.length<=0) {
        self.validationMessage = @"Missing data. Enter your credentials";
        return;
    }
    
    [SVProgressHUD show];
    [self.cloud loginWithUser:self.usernameTextField.text
                     password:self.passwordTextField.text
                   completion:^(NSError *error) {
                       [SVProgressHUD dismiss];
                       if (error) {
                           NSLog(@"Login Fail: \n -> %@", error);
                           self.validationMessage = @"Login Failed";
                           return;
                       }
                       
                       self.validationMessage = @"";
                       self.completion(self, self.cloud.user);        
    }];
}

- (IBAction)cancelButtonPressed:(id)sender {
     self.completion(self, nil);
}


-(void)setValidationMessage:(NSString *)validationMessage
{
    self.validationMessageLabel.text = validationMessage;
    _validationMessage = validationMessage;

    self.validationMessageLabel.hidden = YES;
    if (validationMessage.length>0) {
        self.validationMessageLabel.alpha = 0;
        self.validationMessageLabel.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            self.validationMessageLabel.alpha = 1;
        }];
    }
}

- (NSString *)validationMessage
{
    return _validationMessage;
}

+ (void)presentLoginViewControllerFrom:(UIViewController*)sender
                        withCompletion:(LoginCompletion)completion
{
    
    UIStoryboard *storyboard = sender.storyboard;
    SparkLoginViewController *slvc = [storyboard instantiateViewControllerWithIdentifier:@"SparkLoginViewController"];
    slvc.completion = [completion copy];
    slvc.senderViewController = sender;
    [sender presentViewController:slvc animated:YES completion:nil];
}

@end
