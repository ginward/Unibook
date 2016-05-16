//
//  SearchPaginationManager.m
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
#import "SearchPaginationManager.h"

@implementation SearchPaginationManager

-(instancetype)init{
    if(self=[super init]){
        self.offset = 0;
        self.currentTimestamp = @"0";
    }
    return self;
}

-(void)reinit{
    self.offset = 0;
    self.currentTimestamp = @"0";
}


//update the pagination of the array
//array[0] should be the latest post
-(void)updatePagination:(NSArray *)arr{
    if([arr count]==0) return;
    //if the array still contains that old timestamp
    if([[arr[[arr count]-1] objectForKey:@"timestamp_mil"] isEqualToString:self.currentTimestamp]){
        int m=0;
        for(int i=0;i<[arr count];i++){
            if([self.currentTimestamp isEqualToString:[arr[i] objectForKey:@"timestamp_mil"]]){
                m++;
            }
        }
        self.offset+=m;
    }
    //if the array no longer contains the old timestamp
    else {
        NSString *tmp_ts = [arr[[arr count]-1] objectForKey:@"timestamp_mil"];
        int m=0;
        for(int i=0;i<[arr count];i++){
            if([tmp_ts isEqualToString:[arr[i] objectForKey:@"timestamp_mil"]]){
                m++;
            }
        }
        self.offset = m;
        self.currentTimestamp = tmp_ts;
    }
}


@end