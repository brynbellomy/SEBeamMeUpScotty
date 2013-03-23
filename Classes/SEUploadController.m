//
//  SEUploadController.m
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.20.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <BrynKit/BrynKit.h>
#import <BrynKit/GCDThreadsafe.h>
#import <StateMachine-GCDThreadsafe/StateMachine.h>
#import <libextobjc/EXTScope.h>
#import <CocoaLumberjack/DDLog.h>

#import "SEBeamMeUpScotty.h"
#import "SEUploadController.h"

@interface SEUploadController ()

@property (nonatomic, strong, readwrite) NSObject<SEUploadSessionController> *sessionController;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSURL *videoURL;
@property (nonatomic, assign, readwrite) Float32 progress;

@end



@interface SEUploadController (StateMachine_Private)

//@property (nonatomic, strong, readwrite) NSString *state;

- (void) initializeStateMachine;
- (void) failWithError;

@end



@implementation SEUploadController
@gcd_threadsafe

static int logLevel = LOG_LEVEL_VERBOSE;
+ (int)  ddLogLevel               { return logLevel;  }
+ (void) ddSetLogLevel:(int)level { logLevel = level; }


STATE_MACHINE(^(LSStateMachine *sm) {
    sm.initialState = SEUploadState_NotLoggedIn;

    //
    // states
    //
    [sm addState:SEUploadState_NotLoggedIn];
    [sm addState:SEUploadState_ReadyToUpload];
    [sm addState:SEUploadState_InProgress];
    [sm addState:SEUploadState_Complete];
    [sm addState:SEUploadState_Error];

    //
    // transitions
    //

    [sm when:SEUploadEvent_SignIn transitionFrom:SEUploadState_NotLoggedIn to:SEUploadState_LoggingIn];
    [sm after:SEUploadEvent_SignIn do:^ (SEUploadController *self) {
        [self doSignIn];
    }];



    [sm when:SEUploadEvent_FinishSigningIn transitionFrom:SEUploadState_LoggingIn to:SEUploadState_ReadyToUpload];
    [sm after:SEUploadEvent_FinishSigningIn do:^ (SEUploadController *self) {
        [self doFinishSigningIn];
    }];



    [sm when:SEUploadEvent_UploadVideo transitionFrom:SEUploadState_ReadyToUpload to:SEUploadState_InProgress];
    [sm after:SEUploadEvent_UploadVideo do:^(SEUploadController *self) {
        [self doUploadVideo];
    }];



    [sm when:SEUploadEvent_Complete transitionFrom:SEUploadState_InProgress to:SEUploadState_Complete];
    [sm after:SEUploadEvent_Complete do:^(SEUploadController *self) {
        [self doComplete];
    }];



    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_NotLoggedIn   to:SEUploadState_Error];
    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_LoggingIn     to:SEUploadState_Error];
    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_ReadyToUpload to:SEUploadState_Error];
    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_InProgress    to:SEUploadState_Error];
    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_Complete      to:SEUploadState_Error];
    [sm when:SEUploadEvent_FailWithError transitionFrom:SEUploadState_Error         to:SEUploadState_Error];
    [sm after:SEUploadEvent_FailWithError do:^(SEUploadController *self) {
        yssert_notNilAndIsClass(self.error, NSError);
        [self doFailWithError];
    }];
});




- (instancetype) init
{
    @throw [NSException exceptionWithName:@"NSInternalInconsistencyException"
                                   reason:$str(@"You must call -[%@ initWithSessionController:videoURL:], the designated initializer.", NSStringFromClass([self class]))
                                 userInfo:nil];
    self = nil;
    return nil;
}

- (instancetype) initWithSessionController:(NSObject<SEUploadSessionController> *)sessionController
                                  videoURL:(NSURL *)videoURL
{
    yssert_notNilAndIsClass(videoURL, NSURL);
    yssert(sessionController != nil, @"sessionController is nil.");
    yssert([sessionController conformsToProtocol:@protocol(SEUploadSessionController)], @"sessionController must conform to protocol SEUploadSessionController.");

    self = [super init];
    if (self)
    {
        [self initializeStateMachine];

        _progress          = 0.0f;
        _error             = nil;
        _sessionController = sessionController;
        _videoURL          = videoURL;

        [self initializeReactiveKVO];
    }
    return self;
}

- (void) initializeReactiveKVO
{
}



#pragma mark- (fsm) transitions
#pragma mark-

- (void) doSignIn
{
    lllog(Info, @" ## ###### [ STATE CHANGE (sign in) ] = %@", self.state);
    @weakify(self);

    [self.sessionController signInWithCompletion:^{
        @strongify(self);
        [self finishSigningIn];
    }];
}



- (void) doFinishSigningIn
{
    lllog(Info, @" ## ###### [ STATE CHANGE (finished signing in) ] = %@", self.state);
}



- (void) doUploadVideo
{
    lllog(Info, @" ## ###### [ STATE CHANGE (start upload) ] = %@", self.state);
}



- (void) doComplete
{
    lllog(Info, @" ## ###### [ STATE CHANGE (complete) ] = %@", self.state);
}



- (void) doFailWithError
{
    lllog(Info, @" ## ###### [ STATE CHANGE (error) ] = %@", self.state);
}



- (void) failWithError:(NSError *)error
{
    self.error = error;
    [self failWithError];
}



@end










