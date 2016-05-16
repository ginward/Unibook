//
//  UnibookAuthRequest.h
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

#ifndef UnibookAuthRequest_h
#define UnibookAuthRequest_h

//abstract: http method to requset 
//note that this class only makes json request
@interface UnibookAuthRequest: NSObject <NSURLSessionDelegate>
+(instancetype)sharedUnibookAuthRequest;
-(void)requestPostWithJson:(NSMutableDictionary *)jsonDict requestPath:(NSString *)requestPath callback:(void(^)(NSData *data, NSURLResponse *response, NSError *error))callback;
-(void)requestGetWithPath:(NSString *) requestPath callback:(void(^)(NSData *data, NSURLResponse *response, NSError *error)) callback;
@end

#endif /* UnibookAuthRequest_h */
