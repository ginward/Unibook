//
//  PostItemView.m
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
#import "PostItemView.h"

@interface PostItemView()
-(NSString *)truncateString:(NSString *)string length:(NSInteger)length;
@end

@implementation PostItemView

-(void)setItemWrapper:(PostItemWrapper *)itemWrapper{
    if(_itemWrapper!=itemWrapper){
        _itemWrapper = itemWrapper;
    }
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)lit {
    // If highlighted state changes, need to redisplay.
    if (_highlighted != lit) {
        _highlighted = lit;
        [self setNeedsDisplay];
    }
}

-(void)setProfileImage:(UIImage *)image{
    self.itemWrapper.profileImage = image;
    [self setNeedsDisplay];
}

//draw the view
- (void)drawRect:(CGRect)rect{

#define LEFT_COLUMN_OFFSET 10
#define MIDDLE_COLUMN_OFFSET 170

#define UPPER_ROW_TOP 12
 
    // Color for the main text items
    UIColor *mainTextColor;
    
    // Color for the secondary text items
    UIColor *secondaryTextColor;
    
    UIColor *redColor = [UIColor redColor];
 
    // Choose font color based on highlighted state.
    if (self.highlighted) {
        mainTextColor = [UIColor whiteColor];
        secondaryTextColor = [UIColor whiteColor];
    }
    else {
        mainTextColor = [UIColor blackColor];
        secondaryTextColor = [UIColor darkGrayColor];
    }
    
    //adjust the main font
    UIFont *mainFont;
    mainFont = [UIFont systemFontOfSize:14.0];
    NSDictionary *mainTextAttributes = @{ NSFontAttributeName : mainFont, NSForegroundColorAttributeName : mainTextColor };
    
    //adjust the secondary font
    UIFont *secondaryFont;
     secondaryFont = [UIFont systemFontOfSize:12.0];
    NSDictionary *secondaryTextAttributes = @{ NSFontAttributeName : secondaryFont, NSForegroundColorAttributeName : secondaryTextColor };
    
    UIFont *alertFont;
    alertFont = [UIFont systemFontOfSize:12.0];
    NSDictionary *alertTextAttributes = @{NSFontAttributeName: alertFont, NSForegroundColorAttributeName: redColor};
    
    CGPoint point;
    
    //draw the username
    NSAttributedString *usernameString = [[NSAttributedString alloc] initWithString:self.itemWrapper.name attributes:mainTextAttributes];
    point = CGPointMake(LEFT_COLUMN_OFFSET, UPPER_ROW_TOP  + 2);
    [usernameString drawAtPoint:point];
    
    //draw the post time
    NSAttributedString *postTimeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Posted: %@", self.itemWrapper.time] attributes:secondaryTextAttributes];
    point = CGPointMake(LEFT_COLUMN_OFFSET, UPPER_ROW_TOP + 40);
    [postTimeString drawAtPoint:point];
    
    //draw the university
    NSAttributedString *universityString = [[NSAttributedString alloc] initWithString:self.itemWrapper.university attributes:secondaryTextAttributes];
    point = CGPointMake(LEFT_COLUMN_OFFSET, UPPER_ROW_TOP+55);
    [universityString drawAtPoint:point];
    
    //draw the course code
    NSString *courseCode = [self truncateString:self.itemWrapper.course_code length:10];
    NSAttributedString *courseCodeString = [[NSAttributedString alloc] initWithString:courseCode attributes:mainTextAttributes];
    point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP);
    [courseCodeString drawAtPoint:point];
    
    //draw the course title
    //truncate the string here
    NSString *courseTitle = [self truncateString:self.itemWrapper.course_title length:20];
    NSAttributedString *courseTitleString = [[NSAttributedString alloc] initWithString:courseTitle attributes:mainTextAttributes];
    point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP + 20);
    [courseTitleString drawAtPoint:point];
    
    //draw the price
    NSAttributedString *priceString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Price: $ %@", self.itemWrapper.preferred_price] attributes:secondaryTextAttributes];
    point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP + 40);
    [priceString drawAtPoint:point];
    
    //draw the notification sent hint
    if(self.itemWrapper.notificationSent){
        NSAttributedString *notificationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Sent"] attributes:alertTextAttributes];
        point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP + 55);
        [notificationString drawAtPoint:point];
    }
    
    //draw the sold hint
    if([self.itemWrapper.sold isEqualToString:@"true"]){
        NSAttributedString *notificationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"sold"] attributes:alertTextAttributes];
        point = CGPointMake(MIDDLE_COLUMN_OFFSET, UPPER_ROW_TOP + 70);
        [notificationString drawAtPoint:point];
    }

}

-(NSString *)truncateString:(NSString *)string length:(NSInteger)length{
    if([string length]>length){
        NSMutableString *tmp = [NSMutableString stringWithString:string];
        [tmp deleteCharactersInRange:NSMakeRange(length, [string length]-length)];
        [tmp appendString:@"..."];
        return tmp;
    }
    return string;
}

@end