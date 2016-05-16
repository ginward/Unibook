//
//  SecondViewController.m
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

#import "SearchViewController.h"
#import "SearchPaginationManager.h"
#import "LoadingCell.h"
#import "UnibookTokenRequest.h"
#import "SharedAuthManager.h"
#import <UIKit/UIKit.h>
#import "DetailViewController.h"
@interface SearchViewController ()
@property (strong) NSMutableArray *postEntries;//the post entires obtained from internet
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;//the search bar
@property (strong) SearchPaginationManager *paginationManager;
@property (strong, nonatomic) LoadingCell *loadingCell;
@property NSMutableSet *collectionPost;//my collection of post
@property BOOL initialized;
@property BOOL searchResultEmpty;
-(void)loadingCellAddIndicator;
-(void)loadingCellRemoveIndicator;
-(void)performSearch:(NSString *)txt;
-(NSArray *)reverseArr:(NSArray *)arr;
-(void)updateNotificationStatus;//update the notification status and show sent
@end

#import "PostItemCell.h"
#import "PostItemView.h"
#import "PostItemWrapper.h"

@implementation SearchViewController

//identifiers for the cells
static NSString *MyIdentifier = @"SearchCell";
static NSString *LoadingCellIdentifier = @"LoadingCell";

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //init
    if(!self.initialized){
        self.searchBar.delegate = self;
        self.postEntries = [[NSMutableArray alloc] init];
        self.paginationManager = [[SearchPaginationManager alloc] init];
        self.searchTableview.delegate = self;
        self.searchTableview.dataSource = self;
        self.loadingCell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadingCellIdentifier];
        self.initialized = YES;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.postEntries count]+1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[LoadingCell class]]&&[self.searchBar.text length]>0&&!self.searchResultEmpty) {
        [self loadingCellAddIndicator];
        [self performSearch:self.searchBar.text];
    }
}

#pragma mark - the search bar delegate

//performs action when the search button is clicked
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSString *searchTxt = searchBar.text;
    [self.paginationManager reinit];//reset the pagination
    [self.postEntries removeAllObjects];//remove all the objects from the post entries
    [self performSearch:searchTxt];
    [searchBar resignFirstResponder];
}

//connect to the server and perform the search
-(void)performSearch:(NSString *)txt{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:txt forKey:@"course_code"];
    [dict setObject:self.paginationManager.currentTimestamp forKey:@"lastTimestamp"];
    [dict setObject:[NSString stringWithFormat:@"%ld", (long)self.paginationManager.offset ] forKey:@"offset"];
    //get and set the uniDomain
    SharedAuthManager *authManager = [SharedAuthManager sharedManager];
    NSString *uniDomain = [authManager.credentials objectForKey:UNIDOMAIN_KEY];
    [dict setObject:uniDomain forKey:@"uniDomain"];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@", @"search"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadingCellRemoveIndicator];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                //[self showRefreshError:@"Refresh error!"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //[self removeRefreshError];
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
                //[self showRefreshError:@"Latest Post"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //[self removeRefreshError];
            });
            return;
        }
        
        //reverse the array so that the lastest post is at index 0
        NSArray *postArr = [self reverseArr:[json objectForKey:@"postObject"]];
        
        //no next page
        if([postArr count]==0){
            self.searchResultEmpty = true;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.searchTableview reloadData];
            });
            return;
        }
        self.searchResultEmpty = false;
        //if it is the first time init, discard the previous pointer
        if([self.paginationManager.currentTimestamp isEqualToString:@"0"]){
            self.postEntries = [NSMutableArray arrayWithArray:postArr];
        }
        else {
            for(int i=0;i<[postArr count];i++){
                [self.postEntries addObject: postArr[i]];
            }
        }
        
        [self.paginationManager updatePagination:postArr];
        
        //reload the data in tableview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.searchTableview reloadData];
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
            [self.searchTableview reloadData];
        });
    }];
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
