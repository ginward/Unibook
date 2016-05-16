//
//  EmailFormController.m
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
#import "EmailFormController.h"
#import "BackgroundColor.h"
#import "UnibookAuthRequest.h"
#import "Constants.h"
#import "SharedAuthManager.h"
@interface EmailFormController ()
@property BOOL initLoad;
@property UIActivityIndicatorView *indicatorWheel;
-(void)constructForm;//construct the email form
-(void)addEmailWarning:(NSString *)txt;
-(void)removeEmailWarning;
-(void)validateEmail;
-(void)showLoadingIndicator;
-(void)removeLoadingIndicator;
-(void)addNextButton;
-(void)removeNextButton;
-(void)proceedToNextView;
-(IBAction)alertConditions:(id)sender;
-(IBAction)listUniversities:(id)sender;
@end

@implementation EmailFormController

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
    self.emailField = [[UITextField alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y-36, 200, 35)];
    [self.emailField setBorderStyle:UITextBorderStyleNone];
    self.emailField.textColor = [UIColor blackColor];
    self.emailField.layer.cornerRadius = 1;
    self.emailField.layer.borderWidth = 0;
    self.emailField.layer.borderColor = [UIColor whiteColor].CGColor;
    self.emailField.layer.masksToBounds = NO;
    self.emailField.backgroundColor = [UIColor whiteColor];
    self.emailField.placeholder = @"University Email";
    self.emailField.leftView = paddingViewUsr;
    self.emailField.leftViewMode = UITextFieldViewModeAlways;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.emailField];
    self.emailField.delegate = self;
}


//when user finishes editing the username field, validate online if there is an existing user
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == self.emailField){
        [self showLoadingIndicator];
        [self validateEmail];
    }
}

//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}


//validate the email with server
-(void)validateEmail{
    UnibookAuthRequest *request = [UnibookAuthRequest sharedUnibookAuthRequest];
    NSString *path = [NSString stringWithFormat:@"/%@",@"officialEmail"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.emailField.text forKey:@"email"];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeLoadingIndicator];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self addEmailWarning:@"Server Error!"];
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
                [self addEmailWarning:@"Not a valid University Email"];
            });
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeEmailWarning];
            [self addNextButton];
        });

    }];
}

-(void)addEmailWarning:(NSString *)txt{
    if(!self.emailLabel){
        self.emailLabel = [[UILabel alloc] initWithFrame:CGRectMake([[self view] window].center.x-100, [[self view] window].center.y+10, 200, 35)];
        [self.emailLabel setTextColor:[UIColor blackColor]];
        [self.emailLabel setBackgroundColor:[UIColor clearColor]];
        [self.emailLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        self.emailLabel.text = txt;
        [self.view addSubview:self.emailLabel];
    }
    if(!self.listUniButton){
        self.listUniButton = [[UIButton alloc] initWithFrame:CGRectMake([[self view] window].center.x-150, [[self view] window].center.y+55, 300, 35)];
        [self.listUniButton addTarget:self action:@selector(listUniversities:) forControlEvents:UIControlEventTouchUpInside];
        [self.listUniButton setTitle:@"List of Universities we support" forState:UIControlStateNormal];
        self.listUniButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [self.listUniButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.view addSubview:self.listUniButton];
    }
}

-(void)removeEmailWarning{
    if(self.emailLabel){
        [self.emailLabel removeFromSuperview];
        self.emailLabel=nil;
    }
    if(self.listUniButton){
        [self.listUniButton removeFromSuperview];
        self.listUniButton = nil;
    }
}


-(void)showLoadingIndicator{
    if(!self.indicatorWheel){
        self.indicatorWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([[self view] window].center.x-25, [[self view] window].center.y+30, 50, 50)];
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
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(alertConditions:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
}

-(void)removeNextButton{
    if(self.navigationItem.rightBarButtonItem){
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(IBAction)alertConditions:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Terms and Conditions"
                                                    message:@"By registering, you agree to our terms and conditions:"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Conditions", @"Agree",nil];
    [alert show];
}

//respond to the conditions button
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");
    }
    else if (buttonIndex == 1) {
        NSLog(@"Conditions");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/policy.html", UNIBOOK_URL]]];

    }
    else if (buttonIndex == 2) {
        NSLog(@"Agree");
        [self proceedToNextView];
    }
}

-(void)proceedToNextView{
    //store the email into the database
    SharedAuthManager *manager = [SharedAuthManager sharedManager];
    [manager.tmp_credentials setObject:self.emailField.text forKey:TMP_EMAIL_KEY];
    NSArray *splitByAt = [self.emailField.text componentsSeparatedByString:@"@"];
    NSArray *splitByDot = [(NSString *)splitByAt[[splitByAt count]-1] componentsSeparatedByString:@"."];
    NSString *uniDomain = [NSString stringWithFormat:@"%@.%@", splitByDot[[splitByDot count]-2], splitByDot[[splitByDot count]-1]];
    [manager.tmp_credentials setObject:uniDomain forKey:UNIDOMAIN_KEY];
    dispatch_async(dispatch_get_main_queue(),^{
        [self performSegueWithIdentifier:@"EmailConfirmSegue" sender:self];
    });
}

-(IBAction)listUniversities:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@#services", UNIBOOK_URL]]];
}

@end