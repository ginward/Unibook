//
//  EmailVerifyController.m
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
#import "EmailVerifyController.h"
#import "BackgroundColor.h"
#import "SharedAuthManager.h"
#import "UnibookAuthRequest.h"
#import "UnibookTokenRequest.h"
#import "Constants.h"
#import "LoginViewController.h"
@interface EmailVerifyController()
-(void)constructForm;
-(void)showRegistering;
-(void)removeRegistering;
-(void)registerUser;
-(void)showVerifying:(NSString *)txt;
-(void)removeVerifying;
-(void)showVerificationFailed;
-(NSString *)parseEmailToGetName:(NSString *)email;
-(void)showRegisterError:(NSString *)errTxt;
-(void)verifyCode;
-(void)addNextButton;//add the next button
-(void)alertText:(NSString *)title content:(NSString *)content;
-(IBAction)verifyButtonAction:(id)sender;
-(IBAction)resendButtonAction:(id)sender;
@end

@implementation EmailVerifyController

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //hide the back button
    [self.navigationItem setHidesBackButton:YES animated:YES];
    if(!self.initLoad){
        [self registerUser];
        self.initLoad = YES;
    } else if (self.loginLoad){
        [self constructForm];
    }
}

//register the user using provided credentials
-(void)registerUser{
    [self showRegistering];
    SharedAuthManager *manager = [SharedAuthManager sharedManager];
    NSString *username = [manager.tmp_credentials objectForKey:TMP_USERNAME_KEY];
    NSString *password = [manager.tmp_credentials objectForKey:TMP_PASSWORD_KEY];
    NSString *email = [manager.tmp_credentials objectForKey:TMP_EMAIL_KEY];
    NSString *name = [self parseEmailToGetName:email];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:username forKey:JSON_USERNAME_KEY];
    [dict setObject:password forKey:JSON_PASSWORD_KEY];
    [dict setObject:email forKey:JSON_EMAIL_KEY];
    [dict setObject:name forKey:JSON_NAME_KEY];
    UnibookAuthRequest *request = [UnibookAuthRequest sharedUnibookAuthRequest];
    NSString *path = [NSString stringWithFormat:@"/%@", @"register"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeRegistering];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRegisterError:@"Registration Failed. Server Error"];
            });
            return;
        }
        //now parse the json string
        NSError *json_err;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&json_err];
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]||![json objectForKey:@"token"]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showRegisterError:@"Registration Failed."];
            });
            return;
        }
        //save the token
        [manager.credentials setObject:[json objectForKey:@"token"] forKey:TOKEN_KEY];
        [manager.credentials setObject:[manager.tmp_credentials objectForKey:TMP_USERNAME_KEY] forKey:USERNAME_KEY];
        [manager.credentials setObject:[manager.tmp_credentials objectForKey:UNIDOMAIN_KEY] forKey:UNIDOMAIN_KEY];
        [manager writeToDisk];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self constructForm];
        });
    }];
}

-(NSString *)parseEmailToGetName:(NSString *)email{
    NSArray *items = [email componentsSeparatedByString:@"@"];
    NSString *firstPart = [items objectAtIndex:0];
    NSString *name = [[firstPart stringByReplacingOccurrencesOfString:@"." withString:@" "] capitalizedString];
    return name;
}
//construct the verification form
-(void)constructForm{
    //set padding
    UIView *paddingViewUsr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    [self view].backgroundColor = [UIColor whiteColor];
    self.logoLabel = [[UILabel alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y-150, 200, 35)];
    self.logoLabel.text = @"Hello, Unibook";
    self.logoLabel.textAlignment = NSTextAlignmentCenter;
    [self.logoLabel setFont:[UIFont systemFontOfSize:18]];
    [[self view] addSubview:self.logoLabel];
    self.verificationCodeField = [[UITextField alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y, 200, 35)];
    [self.verificationCodeField setBorderStyle:UITextBorderStyleNone];
    self.verificationCodeField.textColor = [UIColor blackColor];
    self.verificationCodeField.layer.cornerRadius = 1;
    self.verificationCodeField.layer.borderWidth = 0;
    self.verificationCodeField.layer.borderColor = [UIColor whiteColor].CGColor;
    self.verificationCodeField.layer.masksToBounds = NO;
    self.verificationCodeField.backgroundColor = [UIColor whiteColor];
    self.verificationCodeField.placeholder = @"Verification Code";
    self.verificationCodeField.leftView = paddingViewUsr;
    self.verificationCodeField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.verificationCodeField];
    self.verificationCodeField.delegate = self;
    
    UILabel *regFinishedLabel = [[UILabel alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y-100, 200, 100)];
    [regFinishedLabel setTextColor:[UIColor blackColor]];
    [regFinishedLabel setBackgroundColor:[UIColor clearColor]];
    [regFinishedLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
    regFinishedLabel.numberOfLines = 0;
    regFinishedLabel.text = @"Registration suceess! We have sent an email to your official email address with verification code. Please enter the code below";
    [self.view addSubview:regFinishedLabel];
    
    self.verifyButton = [[UIButton alloc] initWithFrame:CGRectMake([[self view] window].center.x-25, [[self view] window].center.y+37, 50, 35)];
    [self.verifyButton addTarget:self action:@selector(verifyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.verifyButton setTitle:@"Verify" forState:UIControlStateNormal];
    self.verifyButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.verifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:self.verifyButton];
};

-(IBAction)verifyButtonAction:(id)sender {
    if(self.verificationCodeField.text.length==4){
      [self verifyCode];
    }
    else {
        [self removeVerifying];
        [self showVerificationFailed];
    }
}

//verify the code with the server
-(void)verifyCode{
    [self showVerifying:@"Verifying..."];
    //get the shared request instance
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@/%@", @"emailVerify", self.verificationCodeField.text];
    [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeVerifying];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showVerificationFailed];
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
                [self showVerificationFailed];
            });
            return;
        }
        
        //proceed to next view
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self addNextButton];
        });
    }];
}

//add the nextbutton
-(void)addNextButton{
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(proceedToNextView:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
}

//proceed to next scene
//ProfileImageSegue
-(IBAction)proceedToNextView:(id)sender{
    NSArray *viewControllers = self.navigationController.viewControllers;
    LoginViewController *loginVC = [viewControllers objectAtIndex:0];
    loginVC.moveToTabView=YES;
    //dismiss all the views on the stack
    [self.navigationController popToRootViewControllerAnimated:YES];
}

//show we are verifying the security code
-(void)showVerifying:(NSString *)txt {
    if(!self.verifyingView){
        self.verifyingView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y+72, 180, 50)];
        self.verifyingView.opaque = NO;
        self.verifyingView.backgroundColor = [UIColor backgroudBlue];
        self.verifyingView.layer.cornerRadius = 15;
        self.verifyingView.alpha=0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.verifyingView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 200, 50)];
        loadingLabel.text = txt;
        loadingLabel.textColor = [UIColor whiteColor];
        [self.verifyingView addSubview: loadingLabel];
        [self.view addSubview:self.verifyingView];
    }
};

//show that the verification failed
-(void)showVerificationFailed{
    if(!self.verifyingView){
        self.verifyingView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y+72, 180, 100)];
        self.verifyingView.opaque = NO;
        self.verifyingView.backgroundColor = [UIColor whiteColor];
        self.verifyingView.layer.cornerRadius = 15;
        self.verifyingView.alpha=0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.verifyingView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Verification Failed";
        loadingLabel.textColor = [UIColor blackColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.verifyingView addSubview: loadingLabel];
        [self.view addSubview:self.verifyingView];
        self.resendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.verifyingView.frame.size.width/2-50, 50, 100, 50)];
        [self.resendButton addTarget:self action:@selector(resendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.resendButton setTitle:@"Resend email" forState:UIControlStateNormal];
        self.resendButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.resendButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.verifyingView addSubview:self.resendButton];
    }
}

//resend the verification email
-(IBAction)resendButtonAction:(id)sender{
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    NSString *path = [NSString stringWithFormat:@"/%@/%@", @"resendVeriMail", self.verificationCodeField.text];
    [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self alertText:@"Resend Email" content:@"Resend Eamil Failed..."];
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
                [self alertText:@"Resend Email" content:@"Resend Eamil Failed..."];
            });
            return;
        }
        
        //proceed to next view
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self alertText:@"Resend Email" content:@"We have resent a verfication email to you ^_^"];
        });
        
    }];
}

-(void)alertText:(NSString *)title content:(NSString *)content{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:content
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

//remove the verifying view
-(void)removeVerifying{
    if(self.verifyingView){
        [self.verifyingView removeFromSuperview];
        self.verifyingView = nil;
    }
};



//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

//tell the user we are registering
-(void)showRegistering{
    if(!self.registeringView){
        self.registeringView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.registeringView.opaque = NO;
        self.registeringView.backgroundColor = [UIColor backgroudBlue];
        self.registeringView.layer.cornerRadius = 15;
        self.registeringView.alpha=0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.registeringView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.registeringView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Registering ...";
        loadingLabel.textColor = [UIColor whiteColor];
        [self.registeringView addSubview: loadingLabel];
        [self.view addSubview:self.registeringView];
    }
}

-(void)showRegisterError:(NSString *)errTxt{
    [self removeRegistering];
    self.registeringView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
    self.registeringView.opaque = NO;
    self.registeringView.backgroundColor = [UIColor backgroudBlue];
    self.registeringView.layer.cornerRadius = 15;
    self.registeringView.alpha=0.7;
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.registeringView.frame.size.width/2-100, 0, 200, 50)];
    loadingLabel.text = errTxt;
    loadingLabel.textColor = [UIColor whiteColor];
    [self.registeringView addSubview: loadingLabel];
    [self.view addSubview:self.registeringView];
}


//tell the user we had successfully registered
-(void)removeRegistering{
    if(self.registeringView){
        [self.registeringView removeFromSuperview];
        self.registeringView=nil;
    }
}

@end