//
//  UnibookMultipartReq.m
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
#import "UnibookMultipartReq.h"
#import "Constants.h"
#import "SharedAuthManager.h"

@interface UnibookMultipartReq ()
-(NSURLSessionConfiguration*) configSession;
@property (strong) NSURLSession *session;
@end

@implementation UnibookMultipartReq

+(instancetype)sharedUniMultiReq{
    static UnibookMultipartReq *uniMult = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uniMult = [[self alloc] init];
    });
    return uniMult;
}

-(instancetype)init{
    if(self = [super init]){
        NSURLSessionConfiguration *sessionConfiguration = [self configSession];
        //set up concurrent operation queue for delegates and callback handlers
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 10;
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:queue];
    }
    return self;
}

-(NSURLSessionConfiguration*) configSession{
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 6;
    return sessionConfiguration;
}

-(void)uploadPostImage:(NSData *)imageData requestPath:(NSString *)requestPath callback:(void (^)(NSData *, NSURLResponse *, NSError *))callback{
    SharedAuthManager *manager = [SharedAuthManager sharedManager];
    NSString *token = [manager.credentials objectForKey:TOKEN_KEY];
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", UNIBOOK_URL, requestPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    //now construct the body data
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", MULTIFORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", @"profileimage"]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", MULTIFORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    //setup request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIFORM_BOUNDARY] forHTTPHeaderField:@"Content-Type"];
    [request addValue:token forHTTPHeaderField:@"x-access-token"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    NSURLSessionTask *imagePostTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        if(callback)
            callback(data, response, error);
    }];
    [imagePostTask resume];
}
@end