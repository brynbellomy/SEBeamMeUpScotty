//
//  SEUpload.h
//  Stan
//
//  Created by bryn austin bellomy on 3.20.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <BrynKit/BrynKit.h>
#import <BrynKit/BrynKitCocoaLumberjack.h>

Key(SEUploadYouTubePrivacySetting_Private,  @"private");
Key(SEUploadYouTubePrivacySetting_Public,   @"public");
Key(SEUploadYouTubePrivacySetting_Unlisted, @"unlisted");

Key(SEUploadState_NotLoggedIn, @"notLoggedIn");
Key(SEUploadState_LoggingIn, @"loggingIn");
Key(SEUploadState_ReadyToUpload, @"readyToUpload");
Key(SEUploadState_InProgress, @"inProgress");
Key(SEUploadState_Complete, @"complete");
Key(SEUploadState_Error, @"error");

Key(SEUploadEvent_SignIn, @"signIn");
Key(SEUploadEvent_FinishSigningIn, @"finishSigningIn");
Key(SEUploadEvent_UploadVideo, @"uploadVideo");
Key(SEUploadEvent_Complete, @"complete");
Key(SEUploadEvent_FailWithError, @"failWithError");

Key(SEUploadSessionControllerNotification_LoginDidFail);

@class SEUploadController;

@protocol SEUploadSessionController

@required

//
// required methods/properties
//

@property (nonatomic, strong, readonly)  NSError *error;
@property (nonatomic, assign, readonly) BOOL isSignedIn;

- (void) signInWithCompletion:(dispatch_block_t)completion;
- (void) signOut;
- (SEUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL;

@end


@class SEUploadController;

#if !defined(lllog)
#   define SEUpload_LOG_CONTEXT 3123
#   define lllog(severity, __FORMAT__, ...)     metamacro_concat(SEUploadLog,severity)((__FORMAT__), ## __VA_ARGS__)
#   define SEUploadLogError(__FORMAT__, ...)    SYNC_LOG_OBJC_MAYBE([SEUploadController ddLogLevel], LOG_FLAG_ERROR,   SEUpload_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#   define SEUploadLogWarn(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([SEUploadController ddLogLevel], LOG_FLAG_WARN,    SEUpload_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#   define SEUploadLogInfo(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([SEUploadController ddLogLevel], LOG_FLAG_INFO,    SEUpload_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#   define SEUploadLogSuccess(__FORMAT__, ...)  SYNC_LOG_OBJC_MAYBE([SEUploadController ddLogLevel], LOG_FLAG_SUCCESS, SEUpload_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#   define SEUploadLogVerbose(__FORMAT__, ...)  SYNC_LOG_OBJC_MAYBE([SEUploadController ddLogLevel], LOG_FLAG_VERBOSE, SEUpload_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#endif





// typedef enum : NSUInteger {
//     SEUploadStatus_NotLoggedIn = 1,
//     SEUploadStatus_ReadyToUpload = 2,
//     SEUploadStatus_InProgress = 3,
//     SEUploadStatus_Complete = 4,
//     SEUploadStatus_Error = 5
// } SEUploadStatus;
//
// static inline NSString *NSStringFromSEUploadStatus(SEUploadStatus status)
// {
//     switch (status) {
//         case SEUploadStatus_NotLoggedIn: return @"SEUploadStatus_NotLoggedIn"; break;
//         case SEUploadStatus_ReadyToUpload: return @"SEUploadStatus_ReadyToUpload"; break;
//         case SEUploadStatus_InProgress: return @"SEUploadStatus_InProgress"; break;
//         case SEUploadStatus_Complete: return @"SEUploadStatus_Complete"; break;
//         case SEUploadStatus_Error: return @"SEUploadStatus_Error"; break;
//         default: return @"(unknown value, not part of enum)"; break;
//     }
// }



