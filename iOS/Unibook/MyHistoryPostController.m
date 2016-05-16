//
//  MyHistoryPostController.m
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
#import  "MyHistoryPostController.h"
#import "UnibookTokenRequest.h"
#import "DetailViewController.h"
@interface MyHistoryPostController()
-(IBAction)deleteAction:(id)sender;
@end
@implementation MyHistoryPostController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

//@Override
- (void)refresh:(UIRefreshControl *)refreshControl{
    NSString *path = [NSString stringWithFormat:@"/%@", @"historyPosts"];
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
                [self showRefreshError:@"No Post"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        //reverse the array so that the lastest post is at index 0
        NSArray *postArr = [self reverseArr:[json objectForKey:@"postObject"]];
        if([postArr count]==0){
            self.postEntries = nil;
            [self.tableView reloadData];
            return;
        }
        self.postEntries = [[NSMutableArray alloc]initWithArray: postArr];
        //reload the data in tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

#pragma mark - tableview delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[self.loadingCell class]]){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    dispatch_async(dispatch_get_main_queue(),^{
        DetailViewController *detailVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"DetailViewID"];
        //now set the data
        detailVC.detailDict = self.postEntries[indexPath.row];
        detailVC.owner = YES;
        detailVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAction:) ];
        detailVC.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
        detailVC.navigationItem.rightBarButtonItem.tag = indexPath.row;
        [self.navigationController pushViewController:detailVC animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

-(IBAction)deleteAction:(id)sender{
    NSInteger row = [(UIBarButtonItem *)sender tag];
    NSDictionary *dict = self.postEntries[row];
    NSString *postId = [dict objectForKey:@"post_id"];
    NSString *path = [NSString stringWithFormat:@"/%@/%@", @"delete", postId];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRefreshError:@"Delete Post Failed..."];
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
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRefreshError:@"Delete Post Failed"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });

    }];
}

@end