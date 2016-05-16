//
//  DetailViewController.m
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
#import "DetailViewController.h"
#import "UnibookTokenRequest.h"

@interface DetailViewController()
@property (strong, nonatomic) UITextView *courseTitleLabel;
@property (strong, nonatomic) UITextView *courseCodeLabel;
@property (strong, nonatomic) UITextView *universityLabel;
@property (strong, nonatomic) UITextView *bookConditionLabel;
@property (strong, nonatomic) UITextView *priceLabel;
@property (strong, nonatomic) UITextView *emailLabel;
@property (strong, nonatomic) UITextView *nameLabel;
@property (strong, nonatomic) UITextView *descriptionLabel;
@property (strong, nonatomic) UITextView *courseTitleField;
@property (strong, nonatomic) UITextView *courseCodeField;
@property (strong, nonatomic) UITextView *universityField;
@property (strong, nonatomic) UITextView *bookConditionField;
@property (strong, nonatomic) UITextView *priceField;
@property (strong, nonatomic) UITextView *emailField;
@property (strong, nonatomic) UITextView *nameField;
@property (strong, nonatomic) UITextView *descriptionField;
@property (strong, nonatomic) UITextView *hintField;
@property (strong, nonatomic) UIButton *noticeButton;
@property BOOL initLoad;
-(CGFloat)calculateTotalHeight;
-(void)constructForm;
-(IBAction)noticeAction:(id)sender;
-(void)showNotifyStatus:(NSString *)txt;
@end

@implementation DetailViewController {
#define MARGIN 20
#define LEFT_COLUMN_OFFSET 10
#define RIGHT_COLUMN_OFFSET 120
#define ROW_HIGHT 40
#define LABEL_WIDTH 100
#define TEXTFIELD_WIDTH 180
#define FONT_SIZE 14
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //init
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if(!self.initLoad){
        [self constructForm];
        self.initLoad = YES;
    }
    
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
}

-(void)constructForm{
    
    self.courseTitleLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, MARGIN+ROW_HIGHT, LABEL_WIDTH, ROW_HIGHT)];
    self.courseTitleLabel.text = @"Course Title";
    [self.courseTitleLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.courseTitleLabel setEditable:NO];
    [self.scrollContentView addSubview:self.courseTitleLabel];
    
    self.courseTitleField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, MARGIN+ROW_HIGHT, TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.courseTitleField setEditable:NO];
    [self.courseTitleField setText:[self.detailDict objectForKey:@"course_title"]];
    [self.courseTitleField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.courseTitleField];
    
    self.courseCodeLabel= [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 2*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.courseCodeLabel.text = @"Course Code";
    [self.courseCodeLabel setEditable:NO];
    [self.courseCodeLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.courseCodeLabel];
    
    self.courseCodeField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 2*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.courseCodeField setEditable:NO];
    [self.courseCodeField setText:[self.detailDict objectForKey:@"course_code"]];
    [self.courseCodeField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.courseCodeField];
    
    self.universityLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 3*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.universityLabel.text = @"University";
    [self.universityLabel setEditable:NO];
    [self.universityLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.universityLabel];
    
    self.universityField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 3*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.universityField setEditable:NO];
    [self.universityField setText:[self.detailDict objectForKey:@"university"]];
    [self.universityField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.universityField];
    
    self.bookConditionLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 4*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.bookConditionLabel.text = @"Book Condition";
    [self.bookConditionLabel setEditable:NO];
    [self.bookConditionLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.bookConditionLabel];
    
    self.bookConditionField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 4*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.bookConditionField setEditable:NO];
    [self.bookConditionField setText:[self.detailDict objectForKey:@"book_condition"]];
    [self.bookConditionField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.bookConditionField];
    
    self.priceLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 5*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.priceLabel.text = @"Preferred Price";
    [self.priceLabel setEditable:NO];
    [self.priceLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.priceLabel];
    
    self.priceField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 5*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.priceField setEditable:NO];
    [self.priceField setText:[self.detailDict objectForKey:@"preferred_price"]];
    [self.priceField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.priceField];
    
    
    self.emailLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 6*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.emailLabel.text = @"Seller Email";
    [self.emailLabel setEditable:NO];
    [self.emailLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.emailLabel];
    
    self.emailField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 6*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.emailField setEditable:NO];
    [self.emailField setText:[self.detailDict objectForKey:@"email"]];
    [self.emailField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.emailField];
    
    
    self.nameLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 7*(MARGIN+ROW_HIGHT), LABEL_WIDTH, ROW_HIGHT)];
    self.nameLabel.text = @"Seller";
    [self.nameLabel setEditable:NO];
    [self.nameLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.nameLabel];
    
    self.nameField = [[UITextView alloc] initWithFrame:CGRectMake(RIGHT_COLUMN_OFFSET, 7*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH, ROW_HIGHT)];
    [self.nameField setEditable:NO];
    [self.nameField setText:[self.detailDict objectForKey:@"name"]];
    [self.nameField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.nameField];
    
    self.descriptionLabel = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 8*(MARGIN+ROW_HIGHT), LABEL_WIDTH+TEXTFIELD_WIDTH, ROW_HIGHT)];
    self.descriptionLabel.text = @"More descriptions";
    [self.descriptionLabel setEditable:NO];
    [self.descriptionLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.descriptionLabel];
    
    self.descriptionField = [[UITextView alloc] initWithFrame:CGRectMake(LEFT_COLUMN_OFFSET, 9*(MARGIN+ROW_HIGHT), TEXTFIELD_WIDTH + LABEL_WIDTH, 3*ROW_HIGHT)];
    [self.descriptionField setEditable:NO];
    [self.descriptionField setText:[self.detailDict objectForKey:@"post_content"]];
    [self.descriptionField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.scrollContentView addSubview:self.descriptionField];
    
    self.noticeButton = [[UIButton alloc] initWithFrame:CGRectMake([self view].frame.size.width/2-60, 9*(MARGIN+ROW_HIGHT)+3*ROW_HIGHT, 120, ROW_HIGHT)];
    [self.noticeButton setTitle:@"I want to buy!" forState:UIControlStateNormal];
    self.noticeButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    [self.noticeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.noticeButton addTarget:self action:@selector(noticeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollContentView addSubview:self.noticeButton];
    self.hintField =[[UITextView alloc] initWithFrame:CGRectMake([self view].frame.size.width/2-(TEXTFIELD_WIDTH)/2, 10*(MARGIN+ROW_HIGHT)+3*ROW_HIGHT, TEXTFIELD_WIDTH, 3*ROW_HIGHT)];
    [self.hintField setEditable:NO];
    [self.hintField setText:@"We will inform the seller via his/her official and verified University Email Address."];
    [self.hintField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [self.hintField setTextColor:[UIColor grayColor]];
    [self.hintField setTextAlignment:NSTextAlignmentCenter];
    //[self.descriptionField setTextAlignment:NSTextAlignmentCenter];
    [self.scrollContentView addSubview:self.hintField];
    
    if([self.detailDict objectForKey:@"notification_sent"]!=nil){
        if([[self.detailDict objectForKey:@"notification_sent"] isEqualToString:@"true"]){
            self.noticeButton.enabled = false;
            [self.noticeButton setTitle:@"Notification Sent" forState:UIControlStateNormal];
            [self.noticeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
    }
    if(self.owner){
        self.noticeButton.enabled = false;
        [self.noticeButton setTitle:@"Posted" forState:UIControlStateNormal];
        [self.noticeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.hintField setText:@"Your post is visible to all university students"];
    }
    self.detailScrollView.contentSize = CGSizeMake([[self view] window].frame.size.width, [self calculateTotalHeight]);
    
}

//notice the buyer
-(IBAction)noticeAction:(id)sender{
    NSString *path = [NSString stringWithFormat:@"/%@/%@", @"notify",[self.detailDict objectForKey:@"post_id"]];
    UnibookTokenRequest *request = [UnibookTokenRequest sharedUnibookTokenRequest];
    [request requestGetWithPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showNotifyStatus:@"Notification failed to sent..."];
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
                [self showNotifyStatus:@"Notification failed to sent..."];
            });
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showNotifyStatus:@"Notification sent ^_^"];
        });
    }];
}

-(void)showNotifyStatus:(NSString *)txt{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unibook Notification"
                                                    message:txt
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(CGFloat)calculateTotalHeight{
    CGFloat height = 18*(MARGIN+ROW_HIGHT)+6*ROW_HIGHT;
    return height;
}
@end