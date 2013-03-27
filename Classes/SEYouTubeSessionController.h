//
//  SEYouTubeSessionController.h
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.18.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SEBeamMeUpScotty.h"

@class SEYouTubeUploadController, GTMOAuth2ViewControllerTouch, GTLServiceYouTube;

@interface SEYouTubeSessionController : NSObject <SEUploadSessionController>

@property (nonatomic, strong, readonly) GTLServiceYouTube *youTubeService;
@property (nonatomic, strong, readonly) NSString *youTubeSignedInUsername;
@property (nonatomic, assign, readonly) BOOL isSignedIn;
@property (nonatomic, strong, readonly) NSError *error;

@property (nonatomic, strong, readonly) UINavigationController *navigationController;
@property (nonatomic, strong, readonly) NSString *keychainItemName;
@property (nonatomic, strong, readonly) NSString *clientID;
@property (nonatomic, strong, readonly) NSString *clientSecret;


//
// lifecycle
//
- (instancetype) init __attribute__((deprecated));
- (instancetype) initWithKeychainItemName:(NSString *)keychainItemName clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret navigationController:(UINavigationController *)navigationController;

//
// sign in/out
//
- (void) signInWithCompletion:(dispatch_block_t)completion;
- (void) signOut;
- (BOOL) attemptYouTubeSignInFromSavedKeychainItem;
- (void) doSignInViewControllerWithCompletion:(dispatch_block_t) completionHandler;

//
// upload controller
//
- (SEYouTubeUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL;

@end





