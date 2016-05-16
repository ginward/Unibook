//
//  Constants.m
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
#import "constants.h"

//init the const objects

NSString *const TOKEN_KEY = @"TOKEN";
NSString *const USERNAME_KEY = @"USERNAME";
NSString *const UNIDOMAIN_KEY = @"UNIDOMAIN";
NSString *const PROFILEIMGPATH_KEY = @"PROFILEIMGPATH";
NSString *const PROFILEIMGTIMESTAMP_KEY = @"PROFILEIMGTIMESTAMP";
unsigned long  const PROFILEIMG_SIZE = 200000; //200kb
CGFloat  const PROFILEIMG_WIDTH = 100;
CGFloat  const PROFILEIMG_HEIGHT = 100;
NSString *const UNIBOOK_URL = @"https://www.hereips.com";
NSString *const MULTIFORM_BOUNDARY = @"uniuniuniuniuni"; //the boundary for multiform submission
NSString *const TMP_USERNAME_KEY = @"TMP_USERNAME";
NSString *const TMP_PASSWORD_KEY = @"TMP_PASSWORD";
NSString *const TMP_EMAIL_KEY = @"TMP_EMAIL";
NSString *const JSON_USERNAME_KEY = @"username";
NSString *const JSON_PASSWORD_KEY = @"password";
NSString *const JSON_EMAIL_KEY = @"email";
NSString *const JSON_NAME_KEY = @"name";
NSString *const TMP_POSTCONTENT_KEY = @"post_content";
NSString *const TMP_COURSECODE_KEY = @"course_code";
NSString *const TMP_COURSETITLE_KEY = @"course_title";
NSString *const TMP_PROFESSOR_KEY = @"professor";
NSString *const TMP_PREFERREDPRICE_KEY = @"preferred_price";
NSString *const TMP_BOOKCONDITION_KEY = @"book_condition";
