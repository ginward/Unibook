//
//  BookConditionController.m
//  Unibook
//
//  Created by Jinhua Wang on 1/3/16.
//  Copyright © 2016 Jinhua Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BookConditionController.h"
#import "SharedPostManager.h"
#import "Constants.h"
@implementation BookConditionController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.conditionPickerView.delegate = self;
    self.conditionPickerView.dataSource = self;
    self.expetcedPrice.delegate = self;
}
- (IBAction)nextButton:(id)sender {
    if([self.expetcedPrice.text length]>0){
        SharedPostManager *manager = [SharedPostManager sharedManager];
        //set the book condition
        NSInteger row = [self.conditionPickerView selectedRowInComponent:0];
        switch (row) {
            case 0:
                [manager.tmp_posts setValue:@"brand_new" forKey:TMP_BOOKCONDITION_KEY];
                break;
                
            case 1:
                [manager.tmp_posts setValue:@"used_good" forKey:TMP_BOOKCONDITION_KEY];
                break;
                
            case 2:
                [manager.tmp_posts setValue:@"used_damage" forKey:TMP_BOOKCONDITION_KEY];
                break;
                
            default:
                [manager.tmp_posts setValue:@"brand_new" forKey:TMP_BOOKCONDITION_KEY];
                break;
        }
        [manager.tmp_posts setValue:self.expetcedPrice.text forKey:TMP_PREFERREDPRICE_KEY];
        dispatch_async(dispatch_get_main_queue(),^{
            [self performSegueWithIdentifier:@"FromConditionToDESC" sender:self];
        });
    }
}

#pragma mark - UIPickerView delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    
    return 1;//Or return whatever as you intend
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    
    return 3;//Or, return as suitable for you...normally we use array for dynamic
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case 0:
            return @"Brand New";
            break;
        case 1:
            return @"Used(Good Condition)";
            break;
        case 2:
            return @"Used";
            break;
    }
    return @"";
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
    if ([string integerValue]||[string isEqualToString:@"0"])
    {
        return YES;
    }
    
    return NO;
}

//hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

@end