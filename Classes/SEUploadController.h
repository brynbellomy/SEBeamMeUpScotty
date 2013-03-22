//
//  SEUploadController.h
//  Stan
//
//  Created by bryn austin bellomy on 3.20.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>

#import "SEUpload.h"

@interface SEUploadController : NSObject

@property (nonatomic, strong, readonly)  NSObject<SEUploadSessionController> *sessionController;
@property (nonatomic, strong, readonly)  NSError *error;
@property (nonatomic, assign, readonly)  Float32 progress;
@property (nonatomic, strong, readonly)  NSURL *videoURL;
@property (nonatomic, strong, readwrite) NSString *state;

+ (int)  ddLogLevel;
+ (void) ddSetLogLevel:(int)level;

- (instancetype) initWithSessionController:(NSObject<SEUploadSessionController> *)sessionController videoURL:(NSURL *)videoURL;

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




