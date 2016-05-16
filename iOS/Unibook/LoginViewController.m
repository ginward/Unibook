//
//  LoginViewController.m
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
#import "LoginViewController.h"
#import "UnibookAuthRequest.h"
#import "UnibookTokenRequest.h"
#import "LoginFormController.h"
#import "SharedAuthManager.h"
@interface LoginViewController()
@property UIView *indicatorView;//show connecting indicator
@property UIView *errorView;//show connection error
@property BOOL loaded;
-(IBAction)showLoginForm:(id)sender;
-(IBAction)showRegisterForm:(id)sender;
-(void)validateToken;
-(void)showLoadingView;
-(void)removeLoadingView;
-(void)setupButtons;
-(void)showError:(NSString *)errStr;
@end

@implementation LoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.moveToTabView){
        dispatch_async(dispatch_get_main_queue(),^{
            [self performSegueWithIdentifier:@"MoveToTabNavSegue" sender:self];
        });

        self.moveToTabView=NO;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self setupButtons];
    //no token, the user needs to login
   if(!self.initToken&&!self.loaded){
       [self validateToken];
       self.loaded=YES;
   }
   if(!self.loaded){
       [self refresh:nil];
   }
}

//@Override
- (void)refresh:(UIRefreshControl *)refreshControl{
        NSString *path = [NSString stringWithFormat:@"/%@", @"postFeedAll"];
        UnibookAuthRequest *request = [UnibookAuthRequest sharedUnibookAuthRequest];
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
                    [self showRefreshError:@"Latest Post"];
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
        }];
}

#pragma mark - tableview delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Preview"
                                                    message:@"Please login to see detailed book offerings. Note that only University students can register."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//@Override
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - perform the segue to the login and register form
-(void)setupButtons{
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStylePlain target:self action:@selector(showRegisterForm:)];
    self.navigationItem.leftBarButtonItem =  leftBarButton;
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(showLoginForm:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)showLoginForm:(id)sender{
    dispatch_async(dispatch_get_main_queue(),^{
            [self performSegueWithIdentifier:@"LoginFormSegue" sender:self];
    });
}

-(IBAction)showRegisterForm:(id)sender{
    dispatch_async(dispatch_get_main_queue(),^{
        [self performSegueWithIdentifier:@"RegisterFormSegue" sender:self];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"LoginFormSegue"]){
        LoginFormController *loginController = segue.destinationViewController;
        loginController.loginViewControllerDelegate = self;
    }
    
}

#pragma mark - the login form

//validate the existing token with the server 
-(void)validateToken{
    //now validating
    [self showLoadingView];
    //get the singleton class
    UnibookTokenRequest *tokenReq = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@",@"validateToken"];
    [tokenReq requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeLoadingView];
        });
        //if there is an error with the connection
        if(error||!data){
            //handle UI on main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showError:@"Connection Error"];
            });
            //after 1 second, show the login form
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeError];
            });
            return;
        }
        NSError *json_err;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&json_err];
        //check if the validation succeeds
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showError:@"Token Expired"];
                SharedAuthManager *manager = [SharedAuthManager sharedManager];
                [manager clean];
            });
            //after 1 second, show the login form
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeError];
            });
            return;
        }
        //proceed to nextview
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self proceedToNextView];
        });
    }];
}

-(void)proceedToNextView{
    self.tokenValid = YES;
    self.initToken = NO;
    dispatch_async(dispatch_get_main_queue(),^{
            [self performSegueWithIdentifier:@"MoveToTabNavSegue" sender:self];
    });
}

#pragma mark - the loading indicators

-(void)showLoadingView{
    if(!self.indicatorView){
        self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.indicatorView.opaque = NO;
        self.indicatorView.backgroundColor = [UIColor grayColor];
        self.indicatorView.layer.cornerRadius = 15;
        self.indicatorView.alpha = 0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.indicatorView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 200, 50)];
        loadingLabel.text = @"Connecting ^_^";
        loadingLabel.textColor = [UIColor whiteColor];
        [self.indicatorView addSubview:loadingLabel];
        [[[self view] window]  addSubview:self.indicatorView];
    }
}

-(void)removeLoadingView{
    if(self.indicatorView){
        [self.indicatorView removeFromSuperview];
        self.indicatorView = nil;
    }
}

-(void)showError:(NSString *)errStr{
    self.errorView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
    self.errorView.opaque = NO;
    self.errorView.backgroundColor = [UIColor grayColor];
    self.errorView.layer.cornerRadius = 15;
    self.errorView.alpha=0.7;
    UILabel *errLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.errorView.frame.size.width/2-100 , 0, 200, 50)];
    errLabel.text = errStr;
    errLabel.textColor=[UIColor whiteColor];
    [errLabel setTextAlignment:NSTextAlignmentCenter];
    [self.errorView addSubview:errLabel];
    [[[self view] window] addSubview:self.errorView];
}


-(void)removeError{
    if(self.errorView){
        [self.errorView removeFromSuperview];
    }
}

@end