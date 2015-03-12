//
//  SparkDeviceDetailsViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkDeviceDetailsViewController.h"


@interface SparkDeviceDetailsViewController ()
@property (strong, nonatomic) NSArray *dataSource;


@end

@implementation SparkDeviceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataSource = @[self.selectedDevice.functions, self.selectedDevice.variables];
    
    self.title = self.selectedDevice.name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section)
    {
        case 0:
            return [self.dataSource[section] count];
            break;
        case 1:
            return [[self.dataSource[section] allKeys] count];
            break;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = @"";
    switch (section)
    {
        case 0:
            if ([self.dataSource[0] count]>0) {
                sectionName = @"Functions";
            }
            break;
        case 1:
            if ([[self.dataSource[1] allKeys] count]>0) {
                sectionName = @"Variables";
            }
            break;
        default:
            sectionName = @"ERR";
            break;
    }
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCell" forIndexPath:indexPath];

    cell.detailTextLabel.text = @"";
    if (indexPath.section==0) {
        NSArray *functions = self.dataSource[indexPath.section];
        cell.textLabel.text = functions[indexPath.row];
        
    } else if (indexPath.section==1) {
        NSDictionary *variables = self.dataSource[indexPath.section];
        NSString *keyOfVariable = [variables.allKeys objectAtIndex:indexPath.row];
        NSString *valueOfVariable = variables[keyOfVariable];
        cell.textLabel.text = keyOfVariable;
        cell.detailTextLabel.text = valueOfVariable;
    }
    
    return cell;
}

@end
