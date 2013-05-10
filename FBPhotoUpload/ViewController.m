//
//  ViewController.m
//  FamousPotato
//
//  Created by 能登 要 on 13/04/10.
//  Copyright (c) 2013年 Irimasu Densan Planning. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger,ShareType )
{
    ShareTypeFacebookPhoto
};

@interface ViewController ()
{
    ShareType _shareType;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)firedFacebookPhoto:(id)sender
{
    _shareType = ShareTypeFacebookPhoto;
    [self firedPickupPhoto:sender];
}

- (void)firedPickupPhoto:(id)sender
{
    
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    
    [self presentModalViewController:imagePicker animated:NO];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage*    originalImage;
    originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissModalViewControllerAnimated:NO];

    const CGSize temporarySize = CGSizeMake(640.0f, 480.0f);
    
    CGFloat ratioBaseSize = temporarySize.width / temporarySize.height;
    CGFloat ratioOriginal = originalImage.size.width / originalImage.size.height;
    
    CGSize normalizedSize = CGSizeZero;
    CGFloat scale = 1.0;
    if( ratioBaseSize <= ratioOriginal ){
        normalizedSize = CGSizeMake(ceil(temporarySize.width)  , ceil(temporarySize.width * (originalImage.size.height / originalImage.size.width) ) );
        scale = temporarySize.width / originalImage.size.width;
    }else{
        normalizedSize = CGSizeMake(ceil(temporarySize.height * (originalImage.size.width / originalImage.size.height) ) , ceil(temporarySize.height) );
        scale = temporarySize.height / originalImage.size.height;
    }
    
    // 写真サイズを変更
    UIGraphicsBeginImageContext(normalizedSize);
    CGContextSaveGState(UIGraphicsGetCurrentContext());
    [originalImage drawInRect:CGRectMake(.0f,.0f, normalizedSize.width, normalizedSize.height)];
    
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    switch (_shareType) {
        case ShareTypeFacebookPhoto:
        {
            ShareViewController* shareViewController = (ShareViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"share_view_controller"];
            shareViewController.imagePicture = resizedImage;
            shareViewController.message = @"写真を共有";
            shareViewController.delegate = self;
            shareViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentModalViewController:shareViewController animated:YES];
        }
            break;
        default:
            break;
    }

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void) shareViewControllerDidCancel:(ShareViewController*)shareViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) shareViewControllerDidFinish:(ShareViewController*)shareViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) shareViewController:(ShareViewController *)shareViewController didFailureError:(NSError *)error
{
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        // 不明なエラー発生
    [self dismissModalViewControllerAnimated:YES];
}


@end
