//
//  SparkDevicesViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkDevicesViewController.h"
#import "SparkLoginViewController.h"
#import <SVProgressHUD.h>
#import <SparkDevice.h>
#import <SparkCloud.h>

@interface SparkDevicesViewController ()

@property (strong, nonatomic) NSMutableArray *devices;
@property (weak, nonatomic) SparkCloud *cloud;

@end

@implementation SparkDevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     self.clearsSelectionOnViewWillAppear = NO;
    
    self.devices = [[NSMutableArray alloc] init];
    self.cloud = [SparkCloud sharedInstance];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.cloud.isUserLoggedIn) {
        [SparkLoginViewController presentLoginViewControllerFromViewController:self
                                                                withCompletion:^(SparkLoginViewController *loginViewController, SparkUser *user) {
                                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                                    NSLog(@"User: %@", user.user);
                                                                }];
    } else {
        NSLog(@"User: %@ is logged in", self.cloud.loggedInUsername);
        self.title = self.cloud.loggedInUsername;
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadData];
}

- (void)loadData {
    [SVProgressHUD show];
    [self.cloud getDevices:^(NSArray *devices, NSError *error) {

        if (error) {
            [SVProgressHUD showErrorWithStatus:@"Error: Can't load devices"];
            return;
        }

        [SVProgressHUD dismiss];
//        self.devices = devices.mutableCopy;
        
        [devices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.devices addObject:obj];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
        NSLog(@"Got devices: %li", self.devices.count);


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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    SparkDevice *device = (SparkDevice*)[self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
