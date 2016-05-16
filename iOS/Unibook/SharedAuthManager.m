//
//  SharedAuthManager.m
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
#import "SharedAuthManager.h"

@interface SharedAuthManager ()
- (NSString *) dataFilePath;
@end

@implementation SharedAuthManager

//the singleton method to return a shared instance
+(instancetype)sharedManager{
    static SharedAuthManager *manager = nil;
    @synchronized(self) {
        if(manager==nil){
            manager = [[self alloc] init];
        }
    }
    return manager;
}

-(instancetype)init{
    if (self = [super init]) {
        _tmp_credentials = [[NSMutableDictionary alloc] init];
        //check if the file at the location exists
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //if the file exists at path, read directly
        if([fileManager fileExistsAtPath:[self dataFilePath]]){
            _credentials = [[NSMutableDictionary alloc] initWithContentsOfFile:[self dataFilePath]];
        }
        //if the file does not exist, init the nsdictionary file and save it
        else {
            _credentials = [[NSMutableDictionary alloc] init];
            [_credentials setObject:@"N/A" forKey:(USERNAME_KEY)];
            [_credentials setObject:@"N/A" forKey:UNIDOMAIN_KEY];
            [_credentials setObject:@"N/A" forKey:(TOKEN_KEY)];
            [_credentials setObject:@"N/A" forKey:(PROFILEIMGPATH_KEY)];
            [_credentials setObject:@"N/A" forKey:(PROFILEIMGTIMESTAMP_KEY)];
            [_credentials writeToFile:[self dataFilePath] atomically:true];
        }
    }
    return self;
}

-(void)clean{
    _credentials = [[NSMutableDictionary alloc] init];
    [_credentials setObject:@"N/A" forKey:(USERNAME_KEY)];
    [_credentials setObject:@"N/A" forKey:UNIDOMAIN_KEY];
    [_credentials setObject:@"N/A" forKey:(TOKEN_KEY)];
    [_credentials setObject:@"N/A" forKey:(PROFILEIMGPATH_KEY)];
    [_credentials setObject:@"N/A" forKey:(PROFILEIMGTIMESTAMP_KEY)];
    [_credentials writeToFile:[self dataFilePath] atomically:true];
}

-(void)writeToDisk{
    [self.credentials writeToFile:[self dataFilePath] atomically:YES];
}

//return the file path that stores the auth file
- (NSString *)dataFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"auth"];
}

@end