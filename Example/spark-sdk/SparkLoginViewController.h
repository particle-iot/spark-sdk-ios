//
//  SparkLoginViewController.h
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <spark-sdk/SparkUser.h>

@class SparkLoginViewController;

typedef void (^LoginCompletion)(SparkLoginViewController *loginViewController, SparkUser *user);


@interface SparkLoginViewController : UIViewController

+ (void)presentLoginViewControllerFromViewController:(UIViewController*)sender
                                     withCompletion:(LoginCompletion)completion;


@end
