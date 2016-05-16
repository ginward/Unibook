//
//  PostItemWrapper.m
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
#import "PostItemWrapper.h"

@interface PostItemWrapper()

@end

@implementation PostItemWrapper

-(instancetype)initWithDictionary:(NSMutableDictionary *)dict{
    self = [super init];
    
    if(self){
        
        if([dict objectForKey:@"post_id"]==nil){
            self.post_id=@"N/A";
        }
        else {
            self.post_id = [dict objectForKey:@"post_id"];
        }
        if([dict objectForKey:@"author"]==nil){
            self.author = @"N/A";
        }
        else {
            self.author = [dict objectForKey:@"author"];
        }
        if([dict objectForKey:@"name"]==nil){
            self.name = @"N/A";
        }
        else {
            self.name = [dict objectForKey:@"name"];
        }
        if([dict objectForKey:@"university"]==nil){
            self.university = @"N/A";
        }
        else {
            self.university = [dict objectForKey:@"university"];
        }
        if([dict objectForKey:@"course_code"]==nil) {
            self.course_code = @"N/A";
        }
        else {
            self.course_code = [dict objectForKey:@"course_code"];
        }
        if([dict objectForKey:@"course_title"]==nil){
            self.course_title = @"N/A";
        }
        else {
            self.course_title = [dict objectForKey:@"course_title"];
        }
        if([dict objectForKey:@"preferred_price"]==nil){
            self.preferred_price = @"N/A";
        }
        else {
            self.preferred_price = [dict objectForKey:@"preferred_price"];
        }
        if([dict objectForKey:@"sold"]==nil){
             self.sold = @"N/A";
        }
        else {
            self.sold = [dict objectForKey:@"sold"];
        }
        if([dict objectForKey:@"time"]==nil){
            self.time = @"N/A";
        }
        else {
            self.time = [dict objectForKey:@"time"];
        }
        self.profileImage = [UIImage imageNamed:@"placeholder"];//defualt image
        if([dict objectForKey:@"notification_sent"]==nil){
            self.notificationSent = false;
        } else {
            self.notificationSent = [[dict objectForKey:@"notification_sent"] boolValue];
        }
    }
    return self;
}
@end