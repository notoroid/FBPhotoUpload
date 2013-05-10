
//
//  ShareViewController.m
//  FBTest3
//
//  Created by 能登 要 on 12/10/02.
//  Copyright (c) 2012年 irimasu. All rights reserved.
//

#import "ShareViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AppDelegate.h"

static NSInteger s_shareViewRevison = 0;

@interface ShareViewController ()
{
    __weak IBOutlet UITextView *_postMessageTextView;
    __weak IBOutlet UIImageView *_backgroundImageView;
    __weak IBOutlet UIImageView *_pictureImageView;
    __weak IBOutlet UIButton *_buttonCancel;
    __weak IBOutlet UIButton *_buttonShare;
    __weak IBOutlet UIActivityIndicatorView *_sendingIndicator;
    __weak IBOutlet UILabel *_labelTitle;
    
    FBRequestConnection *_connection;
    NSArray* _publishPermisions;
}

@property(nonatomic,readonly) FBRequestConnection *connection;
@property(nonatomic,readonly) FBRequestConnection *connection2;
@property (nonatomic,readonly) NSArray* publishPermisions;


@end

@implementation ShareViewController

- (NSArray*) publishPermisions
{
    if( _publishPermisions == nil )
        _publishPermisions = @[@"publish_actions"];
    return _publishPermisions;
}

- (FBRequestConnection *) connection
{
    if( _connection == nil ){
        _connection = [[FBRequestConnection alloc] init];
    }
    return _connection;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _labelTitle.text = @"Share";
    _backgroundImageView.image = _imageBackground;
    _pictureImageView.image = _imagePicture;
    _postMessageTextView.text = _message;
    
    // 編集状態で開始する
    [_postMessageTextView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    _postMessageTextView = nil;
    
    _backgroundImageView = nil;
    _pictureImageView = nil;
    _buttonCancel = nil;
    _buttonShare = nil;
    _sendingIndicator = nil;
    _labelTitle = nil;
    [super viewDidUnload];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{

}

- (void)textViewDidEndEditing:(UITextView *)textView
{

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([_postMessageTextView isFirstResponder] &&
        (_postMessageTextView != touch.view))
    {
        [_postMessageTextView resignFirstResponder];
    }
}

- (IBAction)cancelButtonAction:(id)sender
{
    s_shareViewRevison++;
    
    [_connection cancel];
    
    [_delegate shareViewControllerDidCancel:self];
}

- (IBAction)shareButtonAction:(id)sender {
    // Hide keyboard if showing when button clicked
    if ([_postMessageTextView isFirstResponder]) {
        [_postMessageTextView resignFirstResponder];
    }
    _postMessageTextView.userInteractionEnabled = NO;
    _buttonShare.enabled = NO;
    _labelTitle.text = @"送信中";
    [_sendingIndicator startAnimating];
    
    _pictureImageView.alpha = .5f;
    _postMessageTextView.alpha = .5f;
    _buttonShare.enabled = .5f;
    
    dispatch_block_t sendCompletionBlock = ^{
        _postMessageTextView.userInteractionEnabled = YES;
        _buttonShare.enabled = YES;
        _labelTitle.text = @"Share";
        [_sendingIndicator stopAnimating];
        
        _pictureImageView.alpha = 1.0f;
        _postMessageTextView.alpha =  1.0f;
        _buttonShare.enabled =  1.0f;

        
        [_delegate shareViewControllerDidFinish:self];
    };
    
    
    s_shareViewRevison++;
    NSInteger currentRevision = s_shareViewRevison;
    
    NSString* message = _postMessageTextView.text;
    void (^sendRequest)(dispatch_block_t completionBlock) = ^(dispatch_block_t completionBlock){
        NSMutableDictionary* parametersPhotos = [NSMutableDictionary dictionaryWithDictionary:@{
                                                  @"picture":_imagePicture
                                                 ,@"message":message
                                                 }];
        
        FBRequest *requestPhotos = [FBRequest requestWithGraphPath:@"/me/photos" parameters:parametersPhotos HTTPMethod:@"POST"];
        [requestPhotos startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if( currentRevision == s_shareViewRevison ){
                if (error) {
                    [_delegate shareViewController:self didFailureError:error];
                    // エラー発生
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                }else{
                    completionBlock();
                }
            }else{
                // 既に別の投稿が行われている
            }
        }];
     
    };
    
    void (^blockPermission)(BOOL innerOpenHandler) = ^(BOOL innerOpenHandler){
        FBRequest *requestPermissions = [FBRequest requestWithGraphPath:@"me/permissions" parameters:nil HTTPMethod:@"GET"];
        [requestPermissions startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if( currentRevision == s_shareViewRevison ){
                if (error) {
                    [_delegate shareViewController:self didFailureError:error];
                        // エラー発生
                }else{
                    BOOL photo_upload = NO;
                    
                    NSArray* permissions = result[@"data"];
                    for( NSDictionary* dic in permissions ){
                        NSNumber* valuePhotoUpload = dic[@"photo_upload"];
                        if( valuePhotoUpload != nil )
                            photo_upload = [valuePhotoUpload intValue] ? YES : NO;
                    }
                    
                    if( photo_upload == YES ){
                        sendRequest(sendCompletionBlock);
                    }else{
                        NSMutableArray* newPermissions = [NSMutableArray array];
                        if( photo_upload != YES )
                            [newPermissions addObject:@"photo_upload"];
                        
                        [FBSession.activeSession requestNewPublishPermissions:newPermissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                            if (error) {
                                [_delegate shareViewController:self didFailureError:error];
                                    // エラー発生
                            }else{
                                if( innerOpenHandler != YES ){
                                    sendRequest(sendCompletionBlock);
                                }
                            }
                        }];
                    }
                }
            }
        }];
    
    };
    
    if (FBSession.activeSession.isOpen) {
        blockPermission(NO);
    } else {
        NSScanner* scanner = [NSScanner scannerWithString:[UIDevice currentDevice].systemVersion];
        NSInteger majorVersion = 0;
        [scanner scanInteger:&majorVersion];
        
        // Facebook セッションのチェック
        [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
            if (error) {
                if( currentRevision == s_shareViewRevison ){
                    [_delegate shareViewController:self didFailureError:error];
                    // エラー発生
                }else{
                    // 既に別の投稿が行われている
                }
            } else if (FB_ISSESSIONOPENWITHSTATE(status)) {
                if( currentRevision == s_shareViewRevison ){
                    blockPermission(YES);
                }
            }else{
                // 既に別の投稿が行われている
            }
        }];

    }
    
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

@end
