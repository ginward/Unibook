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
#import "RegisterFormController.h"
#import "BackgroundColor.h"
#import "UnibookAuthRequest.h"
#import "SharedAuthManager.h"
#import "Constants.h"
@interface RegisterFormController()
@property BOOL initLoad;
@property UIActivityIndicatorView *indicatorWheel;
@property BOOL uniqueUsr;//if the username is unique
-(void)constructForm;
-(void)checkPasswordEqual;
-(void)addPasswordEqualWarning:(NSString *)txt;
-(void)removePasswordEqualWarning;
-(void)validateUsername;//check if the username is unique on server
-(void)showLoadingIndicator;
-(void)removeLoadingIndicator;
-(void)addNextButton;
-(void)removeNextButton;
-(IBAction)proceedToNextView:(id)sender;
@end

@implementation RegisterFormController

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(!self.initLoad){
        [self constructForm];
        self.initLoad=YES;
    }
}

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
    [self.usernameTxt addTarget:self action:@selector(checkPasswordEqual) forControlEvents:UIControlEventEditingChanged];
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
    //repeat password
    UIView *paddingViewRepeat = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    self.passwordRepeatTxt = [[UITextField alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y+36, 200, 35)];
    [self.passwordRepeatTxt setBorderStyle:UITextBorderStyleNone];
    self.passwordRepeatTxt.textColor = [UIColor blackColor];
    self.passwordRepeatTxt.layer.cornerRadius = 1;
    self.passwordRepeatTxt.layer.borderWidth = 0;
    self.passwordRepeatTxt.layer.borderColor = [UIColor whiteColor].CGColor;
    self.passwordRepeatTxt.layer.masksToBounds = NO;
    self.passwordRepeatTxt.backgroundColor = [UIColor whiteColor];
    self.passwordRepeatTxt.placeholder = @"Repeat Password";
    self.passwordRepeatTxt.secureTextEntry = YES;
    self.passwordRepeatTxt.leftView = paddingViewRepeat;
    self.passwordRepeatTxt.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.passwordRepeatTxt];
    self.passwordRepeatTxt.delegate = self;
    [self.passwordRepeatTxt addTarget:self action:@selector(checkPasswordEqual) forControlEvents:UIControlEventEditingChanged];
}


-(void)checkPasswordEqual{
    //avoid overwritting important notifications
    if(self.matchLabel && [self.matchLabel.text isEqualToString:@"Username already exists..."]){return;}
    if(![self.passwordTxt.text isEqualToString:self.passwordRepeatTxt.text]){
        [self removePasswordEqualWarning];
        [self addPasswordEqualWarning:@"Passwords do not match"];
        [self removeNextButton];
    }
    else if(!self.usernameTxt.text||self.usernameTxt.text.length<=0){
        [self removePasswordEqualWarning];
        [self addPasswordEqualWarning:@"Username is empty"];
        [self removeNextButton];
    }
    else if([self.usernameTxt.text length]<5||[self.usernameTxt.text length]>20){
        [self removePasswordEqualWarning];
        [self addPasswordEqualWarning:@"Username must be more than 5 characters and less than 20 characters"];
        [self removeNextButton];
    }
    else if([self.passwordRepeatTxt.text length]<5||[self.passwordRepeatTxt.text length]>30){
        [self removePasswordEqualWarning];
        [self addPasswordEqualWarning:@"Password must be more than 5 characters and less than 30 characters"];
        [self removeNextButton];
    }
    else {
        [self removePasswordEqualWarning];
        if(self.uniqueUsr){
            [self addNextButton];
        }
    }
}

-(void)addPasswordEqualWarning:(NSString *)txt{
    if(!self.matchLabel){
        self.matchLabel = [[UILabel alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y+72, 200, 50)];
        self.matchLabel.numberOfLines = 0;
        [self.matchLabel setTextColor:[UIColor blackColor]];
        [self.matchLabel setBackgroundColor:[UIColor clearColor]];
        [self.matchLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        self.matchLabel.text = txt;
        [self.view addSubview:self.matchLabel];
    }
}

-(void)removePasswordEqualWarning{
    if(self.matchLabel){
        [self.matchLabel removeFromSuperview];
        self.matchLabel.text = @"";
        self.matchLabel=nil;
    }
}

-(void)validateUsername{
    UnibookAuthRequest *request = [UnibookAuthRequest sharedUnibookAuthRequest];
    NSString *path = [NSString stringWithFormat:@"/%@",@"uniqueUsr"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.usernameTxt.text forKey:@"username"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeLoadingIndicator];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self addPasswordEqualWarning:@"Server Error!"];
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
                [self removePasswordEqualWarning];
                [self addPasswordEqualWarning:@"Username already exists..."];
                [self removeNextButton];
            });
            self.uniqueUsr = NO;
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.uniqueUsr = YES;
            [self removePasswordEqualWarning];
            [self checkPasswordEqual];
        });
    }];
}

-(void)showLoadingIndicator{
    if(!self.indicatorWheel){
        self.indicatorWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([[self view] window].center.x-25, [[self view] window].center.y+100, 50, 50)];
        [self.indicatorWheel startAnimating];
        self.indicatorWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.indicatorWheel.alpha = 1.0;
        [self.view addSubview:self.indicatorWheel];
    }
};
-(void)removeLoadingIndicator{
    if(self.indicatorWheel){
        [self.indicatorWheel removeFromSuperview];
    }
};

-(void)addNextButton{
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(proceedToNextView:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
}

-(void)removeNextButton{
    if(self.navigationItem.rightBarButtonItem){
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(IBAction)proceedToNextView:(id)sender{
    //save the username and password to the singleton
    SharedAuthManager *manager = [SharedAuthManager sharedManager];
    [manager.tmp_credentials setObject:self.usernameTxt.text forKey:TMP_USERNAME_KEY];
    [manager.tmp_credentials setObject:self.passwordTxt.text forKey:TMP_PASSWORD_KEY];
    dispatch_async(dispatch_get_main_queue(),^{
        [self performSegueWithIdentifier:@"EmailFormSegue" sender:self];
    });
}

#pragma mark - UITextField delegate

- (BOOL) textField: (UITextField *)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString: (NSString *)string {
    //return yes or no after comparing the characters
    // allow backspace
    if (!string.length)
    {
        return YES;
    }
    // allow digit 0 to 9
    if ([string isEqualToString:@" "])
    {
        return NO;
    }
    
    return YES;
}

//when user finishes editing the username field, validate online if there is an existing user
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == self.usernameTxt&&[self.usernameTxt.text length]>5&&[self.usernameTxt.text length]<20){
        [self showLoadingIndicator];
        [self validateUsername];
    }
    [textField  resignFirstResponder];
}

//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

@end