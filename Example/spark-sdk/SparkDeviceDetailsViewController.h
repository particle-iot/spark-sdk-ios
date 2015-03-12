//
//  SparkDeviceDetailsViewController.h
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SparkDevice.h>

@interface SparkDeviceDetailsViewController : UITableViewController

@property (strong, nonatomic) SparkDevice *selectedDevice;

@end
