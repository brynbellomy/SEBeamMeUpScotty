//
//  SEUploadController.h
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.20.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>
#import <StateMachine-GCDThreadsafe/StateMachine.h>

#import "SEBeamMeUpScotty.h"

@interface SEUploadController : NSObject <SEThreadsafeStateMachine>

@property (nonatomic, strong, readonly)  NSObject<SEUploadSessionController> *sessionController;
@property (nonatomic, strong, readonly)  NSError *error;
@property (nonatomic, assign, readonly)  Float32 progress;
@property (nonatomic, strong, readonly)  NSURL *videoURL;

+ (int)  ddLogLevel;
+ (void) ddSetLogLevel:(int)level;

- (instancetype) initWithSessionController:(NSObject<SEUploadSessionController> *)sessionController videoURL:(NSURL *)videoURL;

@end


@interface SEUploadController (StateMachine)

//
// state machine transitions
//

- (void) signIn;
- (void) finishSigningIn;
- (void) uploadVideo;
- (void) complete;
- (void) failWithError:(NSError *)error;
- (void) failWithError;

- (void) doSignIn;
- (void) doFinishSigningIn;
- (void) doUploadVideo;
- (void) doComplete;
- (void) doFailWithError;

@end




