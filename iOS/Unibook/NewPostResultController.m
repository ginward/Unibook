//
//  NewPostResultController.m
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
#import "NewPostResultController.h"
#import "SharedPostManager.h"
#import "Constants.h"
#import "BackgroundColor.h"
#import "SharedPostManager.h"
#import "UnibookTokenRequest.h"
@interface NewPostResultController()
@property (strong) UIView *loadingView;
-(void)showLoading;
-(void)showErr;
-(void)showSuccess;
-(void)removeLoading;
-(void)newPost;
@end

@implementation NewPostResultController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self newPost];
}

//post the new post online
-(void)newPost{
    [self showLoading];
    SharedPostManager *manager = [SharedPostManager sharedManager];
    NSMutableDictionary *dict = manager.tmp_posts;
    NSString *path = [NSString stringWithFormat:@"/%@", @"newPost"];
    
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    [request requestPostWithJson:dict requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeLoading];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showErr];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeLoading];
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
                [self showErr];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeLoading];
            });
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showSuccess];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeLoading];
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
        
    }];
}

-(void)showLoading{
    if(!self.loadingView){
        self.loadingView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y, 180, 50)];
        self.loadingView.opaque = NO;
        self.loadingView.backgroundColor = [UIColor backgroudBlue];
        self.loadingView.layer.cornerRadius = 15;
        self.loadingView.alpha=0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.loadingView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 200, 50)];
        loadingLabel.text = @"Posting...";
        loadingLabel.textColor = [UIColor whiteColor];
        [self.loadingView addSubview: loadingLabel];
        [self.view addSubview:self.loadingView];
    }
};

-(void)showErr{
    
    if(!self.loadingView){
        self.loadingView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y, 180, 50)];
        self.loadingView.opaque = NO;
        self.loadingView.backgroundColor = [UIColor backgroudBlue];
        self.loadingView.layer.cornerRadius = 15;
        self.loadingView.alpha=0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.loadingView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Post Failed...";
        loadingLabel.textColor = [UIColor whiteColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.loadingView addSubview: loadingLabel];
        [self.view addSubview:self.loadingView];
    }

};

-(void)showSuccess{
    if(!self.loadingView){
        self.loadingView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y, 180, 50)];
        self.loadingView.opaque = NO;
        self.loadingView.backgroundColor = [UIColor backgroudBlue];
        self.loadingView.layer.cornerRadius = 15;
        self.loadingView.alpha=0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.loadingView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Post Success!";
        loadingLabel.textColor = [UIColor whiteColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.loadingView addSubview: loadingLabel];
        [self.view addSubview:self.loadingView];
    }
}

-(void)removeLoading{
    if(self.loadingView)
    {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }
};

@end