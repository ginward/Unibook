//
//  FirstViewController.m
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

#import "NewsFeedController.h"
#import "UnibookTokenRequest.h"
#import "SharedAuthManager.h"
#import "SharedPostManager.h"
#import "BackgroundColor.h"
#import "PaginationManager.h"
#import "DetailViewController.h"
#import <UIKit/UIKit.h>
@interface NewsFeedController ()
@property (strong) UIView *refreshView;
@property (strong) PaginationManager *paginationManager;
@property BOOL initialized;
@property NSMutableSet *collectionPost;//my collection of post
-(void)moveToLogoutView;
-(void)nextPage;
-(void)refresh:(UIRefreshControl *)refreshControl;
-(void)loadingCellAddIndicator;
-(void)loadingCellRemoveIndicator;
@end

#import "PostItemCell.h"
#import "PostItemView.h"
#import "PostItemWrapper.h"

@implementation NewsFeedController

//identifiers for the cells
static NSString *MyIdentifier = @"PostCell";
static NSString *LoadingCellIdentifier = @"LoadingCell";

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //init the array
    if(!self.initialized){
        self.postEntries = [[NSMutableArray alloc] init];
        self.paginationManager = [[PaginationManager alloc] init];//init the pagination manager
        self.newsTableView.delegate = self;
        self.newsTableView.dataSource = self;
        self.loadingCell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadingCellIdentifier];
        self.initialized = YES;
    }
}

//delegate for the newsfeedcontroller
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:refreshControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of time zones in the region for the specified section.
    return [self.postEntries count]+1;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
    return @"Posts";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row<self.postEntries.count){
        PostItemCell *cell = (PostItemCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[PostItemCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:MyIdentifier];
        }

        [cell setPostItemWrapper:self.postEntries[indexPath.row]];
        return cell;

    }
    else {
        return self.loadingCell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[LoadingCell class]]) {
        [self loadingCellAddIndicator];
        [self nextPage];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if( [[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[self.loadingCell class]]){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    dispatch_async(dispatch_get_main_queue(),^{
        DetailViewController *detailVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"DetailViewID"];
        //now set the data
        detailVC.detailDict = self.postEntries[indexPath.row];
        [self.navigationController pushViewController:detailVC animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

#pragma mark - load view from internet

//loadnew post from the internet
- (void)refresh:(UIRefreshControl *)refreshControl {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"up" forKey:@"direction"];
    //get the lastest timestamp
    if([self.postEntries count]>0){
        NSString *lastestTimestamp = [self.postEntries[0] objectForKey:@"timestamp_mil"];
        [dict setObject:(lastestTimestamp) forKey:@"clientTimestamp"];
        NSString *clientPostId = [self.postEntries[0] objectForKey:@"post_id"];
        [dict setObject:(clientPostId) forKey:@"clientPostid"];
    }
    else {
        [dict setObject:@"0" forKey:@"clientTimestamp"];
        [dict setObject:@"0" forKey:@"clientPostid"];
    }
    //get and set the uniDomain
    SharedAuthManager *authManager = [SharedAuthManager sharedManager];
    NSString *uniDomain = [authManager.credentials objectForKey:UNIDOMAIN_KEY];
    [dict setObject:uniDomain forKey:@"uniDomain"];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@", @"postFeed"];
    //request for the post feed
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
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
                [self showRefreshError:@"Latest Post"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeRefreshError];
            });
            return;
        }
        
        //check for repeat post 
        BOOL repeat = false;
        if([self.postEntries count]>0){
            if([[postArr[[postArr count]-1] objectForKey:@"post_id"] isEqualToString:[self.postEntries[0] objectForKey:@"post_id"]]){
                repeat = true;
            }
        }
        
        //all brand new post
        if(!repeat){
            self.postEntries = [[NSMutableArray alloc]initWithArray: postArr];
            [self.paginationManager reinit];//reset the pagination
            [self.paginationManager updatePagination:postArr];//update the pagination params
        }else {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:postArr];
            [arr removeObjectAtIndex:([arr count]-1)];
            for(int i=0;i<[self.postEntries count];i++){
                [arr addObject:self.postEntries[i]];
            }
            self.postEntries = arr;
        }
        //reload the data in tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.newsTableView reloadData];
        });
        
        [self updateNotificationStatus];
    }];
    
}

//reverse the array
-(NSArray *)reverseArr:(NSArray *)arr{
    NSMutableArray *tmpArr = [[NSMutableArray alloc] init];
    for(int i=(int)([arr count]-1);i>=0;i--){
        if(arr[i]!=[NSNull null])
        [tmpArr addObject:arr[i]];
    }
    NSArray *result = [[NSArray alloc] initWithArray:tmpArr];
    return result;
}

//load the next page
-(void)nextPage{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"down" forKey:@"direction"];
    [dict setObject:self.paginationManager.currentTimestamp forKey:@"clientTimestamp"];
    [dict setObject:self.paginationManager.clientPostId forKey:@"clientPostid"];
    [dict setObject:[NSString stringWithFormat:@"%ld", (long)self.paginationManager.offset ] forKey:@"clientRepeatPost"];
    //get and set the uniDomain
    SharedAuthManager *authManager = [SharedAuthManager sharedManager];
    NSString *uniDomain = [authManager.credentials objectForKey:UNIDOMAIN_KEY];
    [dict setObject:uniDomain forKey:@"uniDomain"];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@", @"postFeed"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadingCellRemoveIndicator];
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
        
        //no next page
        if([postArr count]==0){
            return;
        }
        
        for(int i=0;i<[postArr count];i++){
            [self.postEntries addObject: postArr[i]];
        }
 
        [self.paginationManager updatePagination:postArr];
        
        //reload the data in tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.newsTableView reloadData];
        });
        
        [self updateNotificationStatus];
        
    }];
}

-(void)updateNotificationStatus{
        NSString *path = [NSString stringWithFormat:@"/%@", @"mycollectionId"];
        UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
        [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
            if(error||!data){
                return;
            }
            //now parse the json string
            NSError *json_err;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&json_err];
            if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]||![json objectForKey:@"postObject"]){
                return;
            }
            NSArray *postArr = [json objectForKey:@"postObject"];
            if([postArr count]==0){
                return;
            }
            BOOL updated = NO;
            for(int i=0;i<[postArr count];i++){
                for(int j=0;j<[self.postEntries count];j++){
                    if([postArr[i] isEqualToString:[self.postEntries[j] objectForKey:@"post_id"]]){
                        NSDictionary *tmp = self.postEntries[j];
                        NSMutableDictionary *tmp_mut = [NSMutableDictionary dictionaryWithDictionary:tmp];
                        [tmp_mut setObject:@"true" forKey:@"notification_sent"];
                        tmp = [NSDictionary dictionaryWithDictionary:tmp_mut];
                        self.postEntries[j] = tmp;
                        updated = YES;
                    }
                }
            }
            if(!updated) return;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.newsTableView reloadData];
            });
        }];
}

-(void)showRefreshError:(NSString *)txt{
    if(!self.refreshView){
        self.refreshView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-50, 180, 50)];
        self.refreshView.opaque = NO;
        self.refreshView.backgroundColor = [UIColor backgroudBlue];
        self.refreshView.layer.cornerRadius = 15;
        self.refreshView.alpha=0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.refreshView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = txt;
        loadingLabel.textColor = [UIColor whiteColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.refreshView addSubview: loadingLabel];
        [self.view addSubview:self.refreshView];
    }
}

-(void)removeRefreshError{
    if(self.refreshView){
        [self.refreshView removeFromSuperview];
        self.refreshView = nil;
    }
}

//move the user to the login view
-(void)moveToLogoutView{
    [self.navigationController.tabBarController dismissViewControllerAnimated:YES completion:nil];
}

//setup the loading cell
-(void)loadingCellAddIndicator {
    if(!self.loadingCell.activityIndicator){
        self.loadingCell.activityIndicator =
        [[UIActivityIndicatorView alloc]
         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        // Setting Frame of Spinner..
        CGFloat x = (self.loadingCell.frame.size.width-60)/2;
        CGFloat y = (self.loadingCell.frame.size.height-60)/2;
        self.loadingCell.activityIndicator.frame = CGRectMake(x, y, 60, 60);
        [self.loadingCell addSubview:self.loadingCell.activityIndicator];
        [self.loadingCell.activityIndicator startAnimating];
    }
}

-(void)loadingCellRemoveIndicator {
    if(self.loadingCell.activityIndicator){
        [self.loadingCell.activityIndicator removeFromSuperview];
        self.loadingCell.activityIndicator = nil;
    }
}

@end
