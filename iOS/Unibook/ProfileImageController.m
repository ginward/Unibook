//
//  ProfileImageController.m
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
#import "ProfileImageController.h"
#import "ImageFileSize.h"
#import "UnibookMultipartReq.h"
#import "LoginViewController.h"
@interface ProfileImageController()
@property UIView *imageUploadView;
- (IBAction)nextAction:(id)sender;
-(void)uploadImage;//performs the image upload
-(void)showUploadingView;//show that the image is uploading
-(void)removeUploadingView;//show that the image upload finishes
-(void)proceedToLoginView;//log user in and move to the tab view
@end

@implementation ProfileImageController


- (void) viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - upload image

-(void)uploadImage{
    [self showUploadingView];
    UnibookMultipartReq *request = [UnibookMultipartReq sharedUniMultiReq];
    NSString *path = [NSString stringWithFormat:@"/uploadProfileImage"];
    [request uploadPostImage:self.imageToUpload requestPath:path callback:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self removeUploadingView];
        });
        if(error||!data){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showUploadingFailed];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeUploadingView];
            });
            return;
        }
        //now parse the json string
        NSError *json_err;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&json_err];
        if(json_err||![json objectForKey:@"success"]||![[json objectForKey:@"success"] boolValue]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showUploadingFailed];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeUploadingView];
            });
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self proceedToLoginView];
        });
    }];
}

-(void)proceedToLoginView{
    NSArray *viewControllers = self.navigationController.viewControllers;
    LoginViewController *loginVC = [viewControllers objectAtIndex:0];
    loginVC.moveToTabView=YES;
    //dismiss all the views on the stack
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)showUploadingView{
    if(!self.imageUploadView){
        self.imageUploadView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.imageUploadView.opaque = NO;
        self.imageUploadView.backgroundColor = [UIColor grayColor];
        self.imageUploadView.layer.cornerRadius = 15;
        self.imageUploadView.alpha = 0.7;
        UIActivityIndicatorView *spinningWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [spinningWheel startAnimating];
        spinningWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinningWheel.alpha = 1.0;
        [self.imageUploadView addSubview:spinningWheel];
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 200, 50)];
        loadingLabel.text = @"Connecting ^_^";
        loadingLabel.textColor = [UIColor whiteColor];
        [self.imageUploadView addSubview:loadingLabel];
        [[self view]  addSubview:self.imageUploadView];
    }
}

//show that the uploading failed
-(void)showUploadingFailed{
    if(!self.imageUploadView){
        self.imageUploadView = [[UIView alloc] initWithFrame:CGRectMake([[self view] window].center.x-90, [[self view] window].center.y-25, 180, 50)];
        self.imageUploadView.opaque = NO;
        self.imageUploadView.backgroundColor = [UIColor grayColor];
        self.imageUploadView.layer.cornerRadius = 15;
        self.imageUploadView.alpha = 0.7;
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.imageUploadView.frame.size.width/2-100, 0, 200, 50)];
        loadingLabel.text = @"Upload Profile Image Failed";
        loadingLabel.textColor = [UIColor whiteColor];
        [loadingLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.imageUploadView addSubview: loadingLabel];
        [self.view addSubview:self.imageUploadView];
    }
}

-(void)removeUploadingView{
    if(self.imageUploadView){
        [self.imageUploadView removeFromSuperview];
        self.imageUploadView = nil;
    }
}

#pragma mark - buttons

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = sourceType; //UIImagePickerControllerSourceTypePhotoLibrary
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


- (IBAction)selectImg:(id)sender {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark - ImageCropViewControllerDelegate

- (void)ImageCropViewControllerSuccess:(ImageCropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage {
    self.profileImg.image = croppedImage;
    ImageFileSize *adjust = [[ImageFileSize alloc] init];
    adjust.callBack = ^(NSError *error, NSData *imageData){
        NSLog(@"<%@:%@:%d>", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
        [[self navigationController] popViewControllerAnimated:YES];
        //set the image upload data
        self.imageToUpload = imageData;
        //show the nextButton
        UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextAction:)];
        self.navigationItem.rightBarButtonItem = nextButton;
    };
    [adjust processImage:croppedImage];
}

- (void)ImageCropViewControllerDidCancel:(ImageCropViewController *)controller{
    [[self navigationController] popViewControllerAnimated:YES];
}

//the action that nextButton performs
- (IBAction)nextAction:(id)sender{
    //upload the image
    if(self.imageToUpload){
        [self uploadImage];
    }
}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.profileImg.image = image;
    //pop off the old controller off the navigation controller stack
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
    //now construct the crop image controller
    ImageCropViewController *controller = [[ImageCropViewController alloc] initWithImage:image];
    controller.delegate = self;
    controller.blurredBackground = YES;
    dispatch_async(dispatch_get_main_queue(),^{
        [[self navigationController] pushViewController:controller animated:YES];
    });
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end