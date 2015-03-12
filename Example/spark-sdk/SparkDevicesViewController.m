//
//  SparkDevicesViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkDevicesViewController.h"
#import "SparkLoginViewController.h"
#import "SparkDeviceDetailsViewController.h"
#import <SVProgressHUD.h>
#import <SparkDevice.h>
#import <SparkCloud.h>
#import "SparkDeviceCell.h"

@interface SparkDevicesViewController ()

@property (strong, nonatomic) NSMutableArray *devices;
@property (weak, nonatomic) SparkCloud *cloud;
@property (weak, nonatomic) SparkDevice *selectedDevice;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL skipReloadOfDevices;

@end

@implementation SparkDevicesViewController


#pragma mark - UIView LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.skipReloadOfDevices = NO;
    
    self.devices = @[].mutableCopy;
    self.cloud = [SparkCloud sharedInstance];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self loginCheck];
    
    if (!self.skipReloadOfDevices && self.cloud.isUserLoggedIn) {
        [self loadData];
    }
}

#pragma mark - Data Loaders
- (void)reloadData {
    NSArray *devicesCopy = self.devices.copy;
    
    [devicesCopy enumerateObjectsUsingBlock:^(SparkDevice *device, NSUInteger idx, BOOL *stop) {
        NSIndexPath *idxPathOfObject = [NSIndexPath indexPathForRow:[self.devices indexOfObject:device] inSection:0];
        [self.devices removeObject:device];
        [self.tableView deleteRowsAtIndexPaths:@[idxPathOfObject] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    [self loadData];
}

- (void)loadData {
    
    if (!self.cloud.isUserLoggedIn) return;
    
    if (!self.refreshControl.isRefreshing) {
        [SVProgressHUD show];
    }
    
    [self.cloud getDevicesPartially:YES completion:^(NSArray *devices, NSError *error) {

        if (error) {
            [SVProgressHUD showErrorWithStatus:@"Error: Can't load devices"];
            return;
        }
        
        [self.refreshControl endRefreshing];
        [SVProgressHUD dismiss];
        
        [devices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.devices addObject:obj];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SparkDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    SparkDevice *device = (SparkDevice*)[self.devices objectAtIndex:indexPath.row];
    [cell configureCellWithDevice:device];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedDevice = self.devices[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.selectedDevice.partial) {
        [self loadFullDevice:self.selectedDevice];
        return;
    }
    
    
    if ([self deviceHasFunctionsOrVariables:self.selectedDevice]) {
        [self performSegueWithIdentifier:@"DeviceDetail" sender:self];
    }
    
}

- (void)loadFullDevice:(SparkDevice*)partialDevice {

        [SVProgressHUD show];
        [self.cloud getDevice:partialDevice.ID completion:^(SparkDevice *fullDevice, NSError *error) {
            [SVProgressHUD dismiss];
            if (error) {
                [SVProgressHUD showErrorWithStatus:@"Can't load full device"];
                return;
            }
            
            NSInteger idx = [self.devices indexOfObject:partialDevice];
            [self.devices replaceObjectAtIndex:idx withObject:fullDevice];
            self.selectedDevice = fullDevice;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            
            if ([self deviceHasFunctionsOrVariables:self.selectedDevice]) {
                [self performSegueWithIdentifier:@"DeviceDetail" sender:self];
            }

        }];


}

#pragma mark - Button Actions
- (IBAction)logoutButtonPressed:(id)sender {
    [self performLogout];
}


#pragma mark - Helpers
- (BOOL)deviceHasFunctionsOrVariables:(SparkDevice*)device
{
    if (device.functions.count <=0 && device.variables.allKeys.count <=0) return NO;
    
    return YES;
}

- (void)performLogout
{
    [self.cloud logout];
    NSLog(@"User: %@", self.cloud.loggedInUsername);
    self.devices = @[].mutableCopy;
    self.title = @"";
    [self.tableView reloadData];
    self.skipReloadOfDevices = NO;
    [self loginCheck];
}


- (void)loginCheck
{
    if (!self.cloud.isUserLoggedIn) {
        [SparkLoginViewController presentLoginViewControllerFrom:self
                                                  withCompletion:^(SparkLoginViewController *loginViewController, SparkUser *user) {
                                                      
                                                      [loginViewController dismissViewControllerAnimated:YES completion:nil];
                                                  }];
    } else {
        self.title = self.cloud.loggedInUsername;
    }
    
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"DeviceDetail"]) {
        self.skipReloadOfDevices = YES;
        SparkDeviceDetailsViewController *ddvc = (SparkDeviceDetailsViewController *)segue.destinationViewController;
        ddvc.selectedDevice = self.selectedDevice;
    }
    
}


@end
