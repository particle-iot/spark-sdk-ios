//
//  SparkDeviceCell.h
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/12/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SparkDevice.h>

@interface SparkDeviceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *statusView;

- (void)configureCellWithDevice:(SparkDevice*)device;

@end
