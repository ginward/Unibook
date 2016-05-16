//
//  ImageFileSize.m
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
#import "Constants.h"
#import "ImageFileSize.h"
//unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:someFilePath error:nil] fileSize];

@interface ImageFileSize ()
@property (strong) NSData *imagedata;
-(NSData *)adjustFileSize:(UIImage *)image;
-(void)adjustImageDimension:(UIImage *)image;
-(NSMutableDictionary *)imageExcBlock:(void (^)(void))block inQueue:(NSOperationQueue *)queue completion:(void (^)(BOOL finished))completion finalBlock:(void (^)(BOOL finished))finalBlock;
@end

@implementation ImageFileSize

-(void)processImage:(UIImage *)image {
    self.image = image;
    // Create and configure the queue to enqueue your operations
    NSOperationQueue *backgroundOperationQueue = [[NSOperationQueue alloc] init];
    NSMutableDictionary *operationDict =
    [self imageExcBlock:^{
        [self adjustImageDimension:self.image];
    }
    inQueue:backgroundOperationQueue
    completion:^(BOOL finished){
        if(finished){
            self.imagedata = [self adjustFileSize:self.image];
        }
    } finalBlock:^(BOOL finished) {
        if(finished){
            if(self.callBack!=nil)
            self.callBack(self.error, self.imagedata);
        }
    }];
}

//@return NSDictionary of Operations
-(NSMutableDictionary *)imageExcBlock:(void (^)(void))block inQueue:(NSOperationQueue *)queue completion:(void (^)(BOOL finished))completion finalBlock:(void (^)(BOOL finished))finalBlock {
    NSOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{completion(blockOperation.isFinished);}];
    NSOperation *finalOperation = [NSBlockOperation blockOperationWithBlock:^{finalBlock(completionOperation.isFinished);}];
    [completionOperation addDependency:blockOperation];
    [finalOperation addDependency:completionOperation];
    [queue addOperation:blockOperation];
    [queue addOperation:completionOperation];
    [[NSOperationQueue currentQueue] addOperation:finalOperation];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:blockOperation forKey:@"blockOperation"];
    [dict setObject:completionOperation forKey:@"completionOperation"];
    [dict setObject:finalOperation forKey:@"finalOperation"];
    return dict;
}

//function to adjust the image size
-(void)adjustImageDimension:(UIImage *)image{
    CGSize size = CGSizeMake(PROFILEIMG_WIDTH, PROFILEIMG_HEIGHT);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, PROFILEIMG_WIDTH, PROFILEIMG_HEIGHT)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = resizedImage;
};

//function to adjust the file size
-(NSData *)adjustFileSize:(UIImage *)image{
    if(self.image!=nil){
        NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation((image), 1.0)];
        unsigned long fileSize = imageData.length;
        int count = 0;
        while (fileSize > PROFILEIMG_SIZE && count < 10) {
            CGFloat compress = 0.8;
            //compress harder
            if(count>1&&count<=5)
                compress = 0.5;
            if(count>5)
                compress = 0.1;
            UIImage *tempImage = image;
            imageData = [NSData dataWithData:UIImageJPEGRepresentation(tempImage, compress)];
            fileSize = imageData.length;
            count++;
        }
        //if the file size is still big, throw an error message
        if(fileSize>PROFILEIMG_SIZE ){
                NSString *domain = @"com.hereips.unibook";
                NSString *desc = NSLocalizedString(@"image", @"size_big");
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
                self.error = [NSError errorWithDomain:domain
                                                     code:001
                                                 userInfo:userInfo];
                return nil;
        }
        NSLog(@"image processing complete!");
        return imageData;
    }
    return nil;
}

@end