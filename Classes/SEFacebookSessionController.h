//
//  SEFacebookSessionController.h
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.16.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Facebook-iOS-SDK/FacebookSDK/Facebook.h>
#import "SEBeamMeUpScotty.h"

typedef void(^FBRequestObjectBlock)(FBRequest *request);

@class SEFacebookUploadController;

@interface SEFacebookSessionController : NSObject <SEUploadSessionController, FBSessionDelegate>

@property (nonatomic, assign, readonly) BOOL isSignedIn;
@property (nonatomic, strong, readonly) NSError *error;

@property (nonatomic, strong, readonly)  Facebook *facebook;
@property (nonatomic, strong, readonly)  NSArray *availablePermissions;
@property (nonatomic, strong, readwrite) NSArray *requestedPermissions;

- (instancetype) init __attribute__((deprecated));
- (instancetype) initWithAppID:(NSString *)appID;

- (void) signInWithCompletion:(dispatch_block_t)completion;
- (void) signInWithRequestedPermissions:(NSArray *)permissions completion:(dispatch_block_t)completion;
- (void) signOut;
- (BOOL) handleOpenURL:(NSURL *)url;
- (SEFacebookUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL;
- (void) videoRequestWithParams:(NSMutableDictionary *)params delegate:(id)delegate requestObjectReady:(FBRequestObjectBlock)requestObjectReady;


@end
