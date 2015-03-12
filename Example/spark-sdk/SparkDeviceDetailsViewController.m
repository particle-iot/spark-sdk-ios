//
//  SparkDeviceDetailsViewController.m
//  Spark-SDK
//
//  Created by Francisco Lobo on 3/11/15.
//  Copyright (c) 2015 Ido Kleinman. All rights reserved.
//

#import "SparkDeviceDetailsViewController.h"
#import <SparkCloud.h>
#import "SparkDeviceDetailCell.h"
#import <SVProgressHUD.h>


@interface SparkDeviceDetailsViewController ()

@property (strong, nonatomic) NSArray *dataSource;
@property (weak, nonatomic) SparkCloud *cloud;
@property (strong, nonatomic) NSMutableDictionary *varValues;
@property (strong, nonatomic) NSMutableArray *funcResponses;
@property (strong, nonatomic) NSMutableArray *observedVariables;
@property (strong, nonatomic) NSTimer *observeTimer;

@end

@implementation SparkDeviceDetailsViewController

#pragma mark - UIView LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.cloud = [SparkCloud sharedInstance];
    self.navigationController.toolbarHidden = NO;
    
    self.varValues = [[NSMutableDictionary alloc] init];
    self.observedVariables = [[NSMutableArray alloc] init];
    self.funcResponses = [[NSMutableArray alloc] initWithCapacity:self.selectedDevice.functions.count];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataSource = @[self.selectedDevice.functions, self.selectedDevice.variables];
    self.title = self.selectedDevice.name;
    
    [self.selectedDevice.functions enumerateObjectsUsingBlock:^(NSDictionary *funcDic, NSUInteger idx, BOOL *stop) {
        [self.funcResponses insertObject:@"tap to call" atIndex:idx];
    }];
    
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
    SparkDeviceDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCell" forIndexPath:indexPath];
    
    cell.subtitleLabel.text = @"";
    [cell.activityIndicator stopAnimating];
    cell.statusImageView.hidden = YES;
    
    if (indexPath.section==0) {
        NSArray *functions = self.dataSource[indexPath.section];
        cell.titleLabel.text = functions[indexPath.row];
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", [self.funcResponses objectAtIndex:indexPath.row]];
    } else if (indexPath.section==1) {
        NSDictionary *variables = self.dataSource[indexPath.section];
        NSString *keyOfVariable = [variables.allKeys objectAtIndex:indexPath.row];
        if (self.varValues[indexPath]) {
            cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", self.varValues[indexPath]];
        } else {
            cell.subtitleLabel.text = @"tap to read";
        }
        
        cell.titleLabel.text = keyOfVariable;
        
        if ([self.observedVariables containsObject:indexPath]) {
            cell.statusImageView.hidden = NO;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SparkDeviceDetailCell *cell = (SparkDeviceDetailCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section==0) {
        
        NSArray *functions = self.dataSource[indexPath.section];
        NSString *functionName = functions[indexPath.row];
        [cell.activityIndicator startAnimating];
        [self.selectedDevice callFunction:functionName
                            withArguments:nil
                               completion:^(NSNumber *number, NSError *error) {
            [cell.activityIndicator stopAnimating];
            if (error) {
                [SVProgressHUD showErrorWithStatus:@"Can't call function!"];
                return;
            }

            [self.funcResponses replaceObjectAtIndex:indexPath.row
                                          withObject:number];
                                   
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            
        }];
        return;
    }
    
    NSDictionary *variables = self.dataSource[indexPath.section];
    NSString *variableName = [variables.allKeys objectAtIndex:indexPath.row];
    
    [cell.activityIndicator startAnimating];
    [self.selectedDevice getVariable:variableName
                          completion:^(id result, NSError *error) {
                              [cell.activityIndicator stopAnimating];
                              if (error) {
                                  [SVProgressHUD showErrorWithStatus:@"Can't get variable!"];
                                  return;
                              }
                              self.varValues[indexPath] = result;
                              [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                              [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                          }];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}


#pragma mark - Button Methods
- (IBAction)observeButtonPressed:(id)sender {
    NSIndexPath *selIndexPath = self.tableView.indexPathForSelectedRow;
    if (selIndexPath.section == 0) return;
    
    if (selIndexPath) {
        if ([self.observedVariables containsObject:selIndexPath]) {
            [self.observedVariables removeObject:selIndexPath];
        } else {
            [self.observedVariables addObject:selIndexPath];
        }
        
        if (self.observedVariables.count>0) {
            [self.observeTimer invalidate];
            self.observeTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                 target:self
                                                               selector:@selector(performVarObservations:)
                                                               userInfo:nil
                                                                repeats:YES];
        } else {
            [self.observeTimer invalidate];
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[selIndexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    
}

- (IBAction)stopAllObservationsButtonPressed:(id)sender {
    [self.observeTimer invalidate];
    [self.observedVariables removeAllObjects];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Observation Methods (Timer Reload of Vars)
- (void)performVarObservations:(NSTimer *)timer {
    if (self.observedVariables.count<=0) {
        [timer invalidate];
        return;
    }
    
    [self.observedVariables enumerateObjectsUsingBlock:^(NSIndexPath *idxPathInTableView, NSUInteger idx, BOOL *stop) {
        [self tableView:self.tableView didSelectRowAtIndexPath:idxPathInTableView];
    }];
}


@end
