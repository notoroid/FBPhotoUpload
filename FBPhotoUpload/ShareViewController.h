//
//  ShareViewController.h
//  FBTest3
//
//  Created by 能登 要 on 12/10/02.
//  Copyright (c) 2012年 irimasu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShareViewControllerDelegate;

@interface ShareViewController : UIViewController<UITextViewDelegate>

@property (strong,nonatomic) NSMutableDictionary *postParams;
@property (strong,nonatomic) UIImage* imageBackground;
@property (strong,nonatomic) UIImage* imagePicture;
@property (strong,nonatomic) NSString* message;
@property (nonatomic,weak) id<ShareViewControllerDelegate> delegate;
@end

@protocol ShareViewControllerDelegate <NSObject>

- (void) shareViewControllerDidCancel:(ShareViewController*)shareViewController;
- (void) shareViewControllerDidFinish:(ShareViewController*)shareViewController;

- (void) shareViewController:(ShareViewController*)shareViewController didFailureError:(NSError*)error;

@end