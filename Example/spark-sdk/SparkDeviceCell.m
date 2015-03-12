//
//  SparkDeviceCell.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/12/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkDeviceCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation SparkDeviceCell

- (void)awakeFromNib {
    self.statusView.layer.cornerRadius = 10;
    self.statusView.backgroundColor = [UIColor colorWithRed:0.114 green:0.690 blue:0.929 alpha:1];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureCellWithDevice:(SparkDevice*)device {
    self.titleLabel.text = device.name;
    self.subtitleLabel.text = device.ID;
    
    if (device.connected) {
        self.statusView.alpha = 0.2;
        [self pulseStatus];
    } else {
        self.statusView.alpha = 0;
        [self.layer removeAllAnimations];
    }
    
    if (device.functions.count>0 || device.variables.count>0) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }

}

- (void)pulseStatus
{
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateKeyframesWithDuration:2.4 delay:1.0 options:UIViewKeyframeAnimationOptionAutoreverse|UIViewKeyframeAnimationOptionRepeat|UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        self.statusView.alpha = 0.8;
    } completion:^(BOOL finished) {
        
    }];
    
}

@end
