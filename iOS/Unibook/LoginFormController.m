//
//  LoginFormController.m
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
#import "LoginFormController.h"
#import "BackgroundColor.h"
#import "UnibookTokenRequest.h"
#import "SharedAuthManager.h"
#import "EmailVerifyController.h"
#import "Constants.h"
@interface LoginFormController()
-(void)loginSucessProceedToApp;
-(void)constructForm;
-(void)loginUser;//the function to login user
-(void)showLoggingIn;
-(void)showLoginFailed;
-(void)removeLoggingView;
-(IBAction)loginAction:(id)sender;
@end

@implementation LoginFormController

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

//construct the form for login
-(void)constructForm{
    //set the padding of the view
    UIView *paddingViewUsr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    [self view].backgroundColor = [UIColor whiteColor];
    //logo Label
    self.logoLabel = [[UILabel alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y-100, 200, 35)];
    self.logoLabel.text = @"Hello, Unibook";
    self.logoLabel.textAlignment = NSTextAlignmentCenter;
    [self.logoLabel setFont:[UIFont systemFontOfSize:18]];
    [[self view] addSubview:self.logoLabel];
    //username
    self.usernameTxt = [[UITextField alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y-36, 200, 35)];
    [self.usernameTxt setBorderStyle:UITextBorderStyleNone];
    self.usernameTxt.textColor = [UIColor blackColor];
    self.usernameTxt.layer.cornerRadius = 1;
    self.usernameTxt.layer.borderWidth = 0;
    self.usernameTxt.layer.borderColor = [UIColor whiteColor].CGColor;
    self.usernameTxt.layer.masksToBounds = NO;
    self.usernameTxt.backgroundColor = [UIColor whiteColor];
    self.usernameTxt.placeholder = @"Username";
    self.usernameTxt.leftView = paddingViewUsr;
    self.usernameTxt.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTxt.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.usernameTxt];
    self.usernameTxt.delegate = self;
    //password
    UIView *paddingViewPwd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    self.passwordTxt = [[UITextField alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y, 200, 35)];
    [self.passwordTxt setBorderStyle:UITextBorderStyleNone];
    self.passwordTxt.textColor = [UIColor blackColor];
    self.passwordTxt.layer.cornerRadius = 1;
    self.passwordTxt.layer.borderWidth = 0;
    self.passwordTxt.layer.borderColor = [UIColor whiteColor].CGColor;
    self.passwordTxt.layer.masksToBounds = NO;
    self.passwordTxt.backgroundColor = [UIColor whiteColor];
    self.passwordTxt.placeholder = @"Password";
    self.passwordTxt.secureTextEntry = YES;
    self.passwordTxt.leftView = paddingViewPwd;
    self.passwordTxt.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.passwordTxt];
    self.passwordTxt.delegate = self;
    //the login button
    self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2+40, 100, 50)];
    [self.loginButton addTarget:self action:@selector(loginAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:self.loginButton];
}

//the login button action
-(IBAction)loginAction:(id)sender{
    if([self.usernameTxt.text length]!=0&&[self.passwordTxt.text length]!=0){
        [self loginUser];
    }
}

-(void)loginUser{
    [self showLoggingIn];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *username = self.usernameTxt.text;
    NSString *password = self.passwordTxt.text;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:username forKey:JSON_USERNAME_KEY];
    [dict setObject:password forKey:JSON_PASSWORD_KEY];
    NSString *path = [NSString stringWithFormat:@"/%@", @"login"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeLoggingView];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showLoginFailed];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeLoggingView];
            });
            return;
        }
        //now parse the json string
        NSError *json_err;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&json_err];
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]){
            //if the user is not verified
            if([[json objectForKey:@"code"] isEqualToString:@"a04"]&&[json objectForKey:@"token"]!=nil){
                NSString *token = [json objectForKey:@"token"];
                SharedAuthManager *manager = [SharedAuthManager sharedManager];
                [manager.credentials setObject:token forKey:TOKEN_KEY];
                NSArray *splitByAt = [[json objectForKey:@"email"] componentsSeparatedByString:@"@"];
                NSArray *splitByDot = [(NSString *)splitByAt[[splitByAt count]-1] componentsSeparatedByString:@"."];
                NSString *uniDomain = [NSString stringWithFormat:@"%@.%@", splitByDot[[splitByDot count]-2], splitByDot[[splitByDot count]-1]];
                [manager.credentials setObject:uniDomain forKey:UNIDOMAIN_KEY];
                [manager.credentials setObject:username forKey:USERNAME_KEY];
                [manager writeToDisk];
                EmailVerifyController *emailVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"EmailVC"];
                emailVC.initLoad = YES;//avoid register procedure
                emailVC.loginLoad = YES;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.navigationController pushViewController:emailVC animated:YES];
                });
                return;
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showLoginFailed];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeLoggingView];
            });
            return;
        }
        //now the login is successful, proceed to app
        dispatch_sync(dispatch_get_main_queue(), ^{
            SharedAuthManager *manager = [SharedAuthManager sharedManager];
            [manager.credentials setObject:[json objectForKey:@"token"] forKey:TOKEN_KEY];
            NSArray *splitByAt = [[json objectForKey:@"email"] componentsSeparatedByString:@"@"];
            NSArray *splitByDot = [(NSString *)splitByAt[[splitByAt count]-1] componentsSeparatedByString:@"."];
            NSString *uniDomain = [NSString stringWithFormat:@"%@.%@", splitByDot[[splitByDot count]-2], splitByDot[[splitByDot count]-1]];
            [manager.credentials setObject:uniDomain forKey:UNIDOMAIN_KEY];
            [manager.credentials setObject:username forKey:USERNAME_KEY];
            //flush to disk
            [manager writeToDisk];
            [self loginSucessProceedToApp];
        });
    }];
}

//show that user is loggin in
-(void)showLoggingIn{
    if(!self.loginView){
        self.loginView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.loginView.opaque = NO;
        self.loginView.backgroundColor = [UIColor backgroudBlue];
        self.loginView.layer.cornerRadius = 15;
        self.loginView.alpha=0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.loginView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 200, 50)];
        loadingLabel.text = @"Logging in...";
        loadingLabel.textColor = [UIColor whiteColor];
        [self.loginView addSubview: loadingLabel];
        [self.view addSubview:self.loginView];
    }
}

//show that user login failed
-(void)showLoginFailed{
    if(!self.loginView){
        self.loginView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.loginView.opaque = NO;
        self.loginView.backgroundColor = [UIColor backgroudBlue];
        self.loginView.layer.cornerRadius = 15;
        self.loginView.alpha=0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.loginView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Verification Failed";
        loadingLabel.textColor = [UIColor whiteColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.loginView addSubview: loadingLabel];
        [self.view addSubview:self.loginView];
    }
}

//remove the logging in view
-(void)removeLoggingView{
    if(self.loginView){
        [self.loginView removeFromSuperview];
        self.loginView = nil;
    }
}

//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

//dismiss the current view controller and tell the previous view controller to move on
-(void)loginSucessProceedToApp{
    self.loginViewControllerDelegate.moveToTabView = YES;
    [self.navigationController popViewControllerAnimated:YES];
}
@end