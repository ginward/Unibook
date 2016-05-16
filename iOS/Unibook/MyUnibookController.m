//
//  MyUnibookController.m
//  Unibook
//

/*
 * Copyright Jinhua Wang, 2015
 * The MIT License (MIT)
 * Copyright (c) <2015> <Jinhua Wang>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "MyUnibookController.h"
#import <UIKit/UIKit.h>
@interface MyUnibookController()
@property (strong, nonatomic) UIButton *myPostButton;
@property (strong, nonatomic) UIButton *myCollectionButton;
@property (strong) UITableView *settingsTableView;
@property BOOL initLoad;
-(void)constructForm;;
@end

@implementation MyUnibookController {
#define TABLEHEIGHT 300
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(!self.initLoad){
        [self constructForm];
        self.initLoad = YES;
    }
}

//construct the user interfacess
-(void)constructForm{
    if(!self.settingsTableView){
        self.settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake([[self view] window].center.x-([[self view] window].frame.size.width-20)/2, ([[self view] window].center.y)-TABLEHEIGHT/2, [[self view] window].frame.size.width-20, TABLEHEIGHT)];
        self.settingsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.settingsTableView.delegate = self;
        self.settingsTableView.dataSource = self;
        //remove the extra cells
        self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        //remove the cell border
        self.settingsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.view addSubview:self.settingsTableView];
    }
}

#pragma mark - TableView delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//there are three rows in the table view
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"UnibookCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.backgroundView = [[UIView alloc] init];
    [cell.backgroundView setBackgroundColor:[UIColor clearColor]];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"My Collections";
            break;
            
        case 1:
            cell.textLabel.text = @"Interested Buyers";
            break;
            
        default:
            break;

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {
        case 0:
            break;
        case 1:
            break;
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end