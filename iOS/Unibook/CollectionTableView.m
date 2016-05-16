//
//  CollectionTableView.m
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
#import "CollectionTableView.h"
#import "UnibookTokenRequest.h"
#import "SharedAuthManager.h"
@interface CollectionTableView()
-(IBAction)logoutAction:(id)sender;
-(IBAction)historyAction:(id)sender;
@end

@implementation CollectionTableView
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logoutAction:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"My Posts" style:UIBarButtonItemStylePlain target:self action:@selector(historyAction:)];
    [self refresh:nil];
}

-(IBAction)logoutAction:(id)sender{
    SharedAuthManager *manager = [SharedAuthManager sharedManager];
    [manager clean];
    [self.navigationController.tabBarController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)historyAction:(id)sender{
    dispatch_async(dispatch_get_main_queue(),^{
        [self performSegueWithIdentifier:@"HistorySegue" sender:self];
    });
}

#pragma mark - delegate for uitableview
//@Override
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
    return @"My Books";
}


//@Override
- (void)refresh:(UIRefreshControl *)refreshControl {
    NSString *path = [NSString stringWithFormat:@"/%@", @"mycollection"];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(refreshControl)
            [refreshControl endRefreshing];//end refreshing
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRefreshError:@"Refresh error!"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        //now parse the json string
        NSError *json_err;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&json_err];
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]||![json objectForKey:@"postObject"]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRefreshError:@"Latest Post"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        //reverse the array so that the lastest post is at index 0
        NSArray *postArr = [self reverseArr:[json objectForKey:@"postObject"]];
        if([postArr count]==0){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRefreshError:@"No Post"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        self.postEntries = [[NSMutableArray alloc]initWithArray: postArr];
        //reload the data in tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        [self updateNotificationStatus];
    }];
}

@end