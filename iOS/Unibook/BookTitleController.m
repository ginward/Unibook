//
//  BookTitleController.m
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
#import "BookTitleController.h"
#import "SharedPostManager.h"
#import "Constants.h"
@implementation BookTitleController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.courseCodeTxt.delegate = self;
    self.CourseTitleTxt.delegate = self;
}
- (IBAction)nextButton:(id)sender {
    if([self.courseCodeTxt.text length]>0 && [self.CourseTitleTxt.text length]>0){
        SharedPostManager *manager = [SharedPostManager sharedManager];
        [manager reInitPosts];
        [manager.tmp_posts setObject:self.courseCodeTxt.text forKey:TMP_COURSECODE_KEY];
        [manager.tmp_posts setObject:self.CourseTitleTxt.text forKey:TMP_COURSETITLE_KEY];
        dispatch_async(dispatch_get_main_queue(),^{
            [self performSegueWithIdentifier:@"FromTitleToCondition" sender:self];
        });
    }
}

//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

@end