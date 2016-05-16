//
//  SharedPostManager.m
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
#import "SharedPostManager.h"
#import "Constants.h"
@interface SharedPostManager()

@end

@implementation SharedPostManager

//the singleton method to return a shared instance
+(instancetype)sharedManager{
    static SharedPostManager *manager = nil;
    @synchronized(self) {
        if(manager == nil){
            manager = [[self alloc] init];
        }
    }
    return manager;
}

-(instancetype)init{
    if(self=[super init]){
        self.tmp_posts = [[NSMutableDictionary alloc] init];
        [self.tmp_posts setObject:@"" forKey:TMP_COURSETITLE_KEY];
        [self.tmp_posts setObject:@"" forKey:TMP_COURSECODE_KEY];
        [self.tmp_posts setObject:@"" forKey:TMP_PROFESSOR_KEY];
        [self.tmp_posts setObject:@"" forKey:TMP_PREFERREDPRICE_KEY];
        [self.tmp_posts setObject:@"" forKey:TMP_POSTCONTENT_KEY];
        [self.tmp_posts setObject:@"" forKey:TMP_BOOKCONDITION_KEY];
    }
    return self;
}

//init the post to "" again
-(void)reInitPosts{
    if(!self.tmp_posts){
    self.tmp_posts = [[NSMutableDictionary alloc]
                      init];
    }
    [self.tmp_posts setObject:@"" forKey:TMP_COURSETITLE_KEY];
    [self.tmp_posts setObject:@"" forKey:TMP_COURSECODE_KEY];
    [self.tmp_posts setObject:@"" forKey:TMP_PROFESSOR_KEY];
    [self.tmp_posts setObject:@"" forKey:TMP_PREFERREDPRICE_KEY];
    [self.tmp_posts setObject:@"" forKey:TMP_POSTCONTENT_KEY];
    [self.tmp_posts setObject:@"" forKey:TMP_BOOKCONDITION_KEY];
}

@end