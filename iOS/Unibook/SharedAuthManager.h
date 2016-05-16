//
//  SharedAuthManager.h
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

/*
 * abstract: manages the token and login credentials of the user, also caches the profile of the user
 * this is a singleton class
 */

#ifndef SharedAuthManager_h
#define SharedAuthManager_h
#import "Constants.h"
@interface SharedAuthManager : NSObject

/*
 * Credentials:
 *  {
 *    token: String,
 *    username:String,
 *    profileImgPath:String,
 *    profileImgTimestamp: String,
 *  }
 */
@property (strong) NSMutableDictionary *credentials;
@property (strong) NSMutableDictionary *tmp_credentials;//credentials to use while in authorization
//return the singleton class
+ (id)sharedManager;
- (void)writeToDisk;//save the credentials in memory to the disk
- (void)clean;//clean all of users' credentials
@end

#endif /* SharedAuthManager_h */
