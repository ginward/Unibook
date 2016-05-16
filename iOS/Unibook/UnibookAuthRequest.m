//
//  UnibookAuthRequest.m
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
#import "UnibookAuthRequest.h"
#import "constants.h"

@interface UnibookAuthRequest()
-(NSURLSessionConfiguration*) configSession;
@property (strong) NSURLSession *session;
@end

@implementation UnibookAuthRequest

#pragma mark - init singleton

//method that returns a singleton object
+(instancetype)sharedUnibookAuthRequest{
    static UnibookAuthRequest *myUniAuth = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        myUniAuth = [[self alloc] init];
    });
    return myUniAuth;
}
//init the UnibookAuthRequest
-(instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *sessionConfiguration = [self configSession];
        //set up concurrent operation queue for delegates and callback handlers
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 10;
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:queue];
    }
    return self;
}
//class to configure the session
-(NSURLSessionConfiguration*) configSession {
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 6;
    return sessionConfiguration;
}

#pragma mark - request methods

//post request to send the json string
-(void)requestPostWithJson:(NSMutableDictionary *)jsonDict requestPath:(NSString *)requestPath callback:(void (^)(NSData * callback_data, NSURLResponse * callback_res, NSError * callback_err))callback{
    //parse url
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", UNIBOOK_URL, requestPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    //parse json
    NSError *jsonErr;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&jsonErr];
    if(!jsonData){
        //tell the callback that something goes wrong
        if(callback)
        callback(nil, nil, jsonErr);
        return;
    }
    //setup request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonData];
    [request setHTTPMethod:@"POST"];
    NSURLSessionDataTask *postTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        callback(data, response, error);
    }];
    [postTask resume];
}

//get request with parameters in the url path
-(void) requestGetWithPath:(NSString *)requestPath callback:(void (^)(NSData *path_data, NSURLResponse *path_res, NSError *path_err))callback{
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", UNIBOOK_URL, requestPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    NSURLSessionDataTask *getTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        callback(data, response, error);
    }];
    [getTask resume];
}

@end