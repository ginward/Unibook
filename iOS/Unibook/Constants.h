//
//  Constants.h
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

//abstract: the constant variables for the project

#ifndef Constants_h
#define Constants_h
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const TOKEN_KEY;
FOUNDATION_EXPORT NSString *const USERNAME_KEY;
FOUNDATION_EXPORT NSString *const UNIDOMAIN_KEY;
FOUNDATION_EXPORT NSString *const PROFILEIMGPATH_KEY;
FOUNDATION_EXPORT NSString *const PROFILEIMGTIMESTAMP_KEY;
FOUNDATION_EXPORT unsigned long const PROFILEIMG_SIZE;
FOUNDATION_EXPORT CGFloat  const PROFILEIMG_WIDTH;
FOUNDATION_EXPORT CGFloat  const PROFILEIMG_HEIGHT;
FOUNDATION_EXPORT NSString *const UNIBOOK_URL;
FOUNDATION_EXPORT NSString *const MULTIFORM_BOUNDARY;
//credential keys for register
FOUNDATION_EXPORT NSString *const TMP_USERNAME_KEY;
FOUNDATION_EXPORT NSString *const TMP_PASSWORD_KEY;
FOUNDATION_EXPORT NSString *const TMP_EMAIL_KEY;
FOUNDATION_EXPORT NSString *const JSON_USERNAME_KEY;
FOUNDATION_EXPORT NSString *const JSON_PASSWORD_KEY;
FOUNDATION_EXPORT NSString *const JSON_EMAIL_KEY;
FOUNDATION_EXPORT NSString *const JSON_NAME_KEY;
//key for new posts
FOUNDATION_EXPORT NSString *const TMP_POSTCONTENT_KEY;
FOUNDATION_EXPORT NSString *const TMP_COURSECODE_KEY;
FOUNDATION_EXPORT NSString *const TMP_COURSETITLE_KEY;
FOUNDATION_EXPORT NSString *const TMP_PROFESSOR_KEY;
FOUNDATION_EXPORT NSString *const TMP_PREFERREDPRICE_KEY;
FOUNDATION_EXPORT NSString *const TMP_BOOKCONDITION_KEY;
#endif /* Constants_h */
