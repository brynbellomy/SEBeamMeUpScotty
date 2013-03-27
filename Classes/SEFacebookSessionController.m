//
//  SEFacebookSessionController.m
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.16.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Facebook-iOS-SDK/FacebookSDK/Facebook.h>
#import <BrynKit/BrynKitCocoaLumberjack.h>
#import <BrynKit/RACSubject+SERACHelpers.h>
#import <libextobjc/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACQueueScheduler.h>

#import "SEFacebookSessionController.h"
#import "SEFacebookUploadController.h"
#import "SEBeamMeUpScotty.h"

@interface SEFacebookSessionController ()
    @property (nonatomic, strong, readwrite) Facebook *facebook;
    @property (nonatomic, strong, readwrite) NSArray *availablePermissions;
    @property (nonatomic, strong, readwrite) NSError *error;
    @property (nonatomic, assign, readwrite) BOOL isSignedIn;
    @property (nonatomic, assign, readwrite) dispatch_queue_t queue;

    // all requests making use of the same fb session must occur on the same
    // thread.  `fbSessionScheduler` ensures that that happens.
//    @property (nonatomic, strong, readwrite) RACQueueScheduler *fbSessionScheduler;
@end

@implementation SEFacebookSessionController

- (instancetype) init
{
    @throw [NSException exceptionWithName:@"NSInternalInconsistencyException" reason:@"You must call -[SEFacebookSessionController initWithAppID:], the designated initializer." userInfo:nil];
    self = nil;
    return nil;
}

- (instancetype) initWithAppID:(NSString *)appID
{
    yssert_onMainThread(); //([NSThread isMainThread], @"[SEFacebookSessionController initWithAppID:] must be called from main thread.");
    self = [super init];
    if (self) {
        _error = nil;

        _queue = dispatch_queue_create("SEFacebookSessionController", DISPATCH_QUEUE_SERIAL);               yssert_notNil(_queue);
        dispatch_set_target_queue(_queue, dispatch_get_main_queue());

        // unfortunately, this has to be performed on the main thread only because we want
        // to implement `-handleOpenURL:`, which comes in on the main thread, and all of our
        // fb stuff has to happen on the same thread
//        _fbSessionScheduler = [[RACQueueScheduler alloc] initWithName:@"sefacebooksessioncontroller" targetQueue:_queue];

        [self initializeReactiveKVO];

//        @weakify(self);
//        dispatch_async(_queue, ^{
//            @strongify(self);
            _facebook = [[Facebook alloc] initWithAppId:appID andDelegate:self];
//        });
    }
    return self;
}



- (void) initializeReactiveKVO
{
    yssert_onMainThread();

    [self rac_addDeallocDisposable: [[[RACAbleWithStart(self.availablePermissions) setNameWithFormat:COLOR_YELLOW(@"self.availablePermissions")] lllogAll]
                                     subscribeNext:^(id x) {
                                         lllog(Warn, @"NEXT inside availablePermissions = %@", x);
                                     } error:^(NSError *error) {
                                         lllog(Error, @"ERROR inside availablePermissions = %@", error);
                                     } completed:^{
                                         lllog(Success, @"COMPLETED inside availablePermissions");
                                     }]];


    [self rac_addDeallocDisposable: [[[RACAbleWithStart(self.requestedPermissions) setNameWithFormat:COLOR_YELLOW(@"self.requestedPermissions")] lllogAll]
                                     subscribeNext:^(id x) {
                                         lllog(Warn, @"NEXT inside requestedPermissions = %@", x);
                                     } error:^(NSError *error) {
                                         lllog(Error, @"ERROR inside requestedPermissions = %@", error);
                                     } completed:^{
                                         lllog(Success, @"COMPLETED inside requestedPermissions");
                                     }]];

    [self rac_addDeallocDisposable: [[[RACAbleWithStart(self.error) setNameWithFormat:COLOR_YELLOW(@"self.error")] lllogAll] subscribeNext:^(NSError *error) {
        lllog(Error, @"self.error = %@", error);
    }]];
}



- (void) dealloc
{
    lllog(Warn, @"-[%@ dealloc] is being called", [self class]);

    if (_queue != nil) {
        dispatch_release(_queue);
        _queue = nil;
    }
}



- (SEFacebookUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL
{
    yssert_onMainThread();
    return [[SEFacebookUploadController alloc] initWithSessionController:self videoURL:videoFileURL];
}



- (void) signInWithRequestedPermissions:(NSArray *)permissions
                             completion:(dispatch_block_t)completion
{
    yssert_onMainThread();
    self.requestedPermissions = [permissions copy];
    [self signInWithCompletion:completion];
}



- (void) signInWithCompletion:(dispatch_block_t)completion
{
    yssert_onMainThread();

    yssert_notNilAndIsClass(self.requestedPermissions, NSArray);
    if (self.requestedPermissions.count <= 0) {
        lllog(Warn, @"self.requestedPermissions.count <= 0");
    }
    @weakify(self);

    self.isSignedIn = NO;
    self.availablePermissions = @[];

    __block RACCompoundDisposable *compoundDisposable = nil;
    RACDisposable *disposable = nil, *miscDisposable = nil;

    disposable = [[[[[RACAbleWithStart(self.isSignedIn)
                      notNil]
                      distinctUntilChanged]
                      setNameWithFormat:@"SEFacebookSessionController.isSignedIn"]
                      lllogAll]
                      subscribeNext:^(NSNumber *isLoggedIn) {
                          @strongify(self);

                          lllog(Info, COLOR_BLUE(@"<< self.isSignedIn >> next -> %@"), isLoggedIn);

                          if (isLoggedIn.boolValue == NO)
                          {
                              yssert_notNilAndIsClass(self.requestedPermissions, NSArray);

                              yssert(self.queue != nil, @"self.queue is nil.");
                              dispatch_async(self.queue, ^{
                                  yssert_onMainThread();
                                  @strongify(self);
                                  yssert_notNilAndIsClass(self.facebook, Facebook);
                                  yssert_notNilAndIsClass(self.requestedPermissions, NSArray);

                                  [self.facebook authorize:self.requestedPermissions];
                              });
                          }
                          else
                          {
                              if (completion != nil) {
                                  yssert_notNil(self.queue);
                                  dispatch_async(self.queue, completion);
                              }
                              else {
                                  lllog(Warn, @"SEFacebookSessionController completion block is nil.");
                              }

                              [compoundDisposable dispose];
                              compoundDisposable = nil;
                          }
                      }
                      error:^(NSError *error) {
                          @strongify(self);
                          lllog(Error, @"SEFacebookSessionController.isSignedIn [ERROR] = %@", error);

                          self.error = error;
                          self.isSignedIn = NO;

                          if (completion != nil) {
                              yssert(self.queue != nil, @"self.queue is nil.");
                              dispatch_async(self.queue, completion);
                          }
                          else {
                              lllog(Warn, @"SEFacebookSessionController completion block is nil.");
                          }

                          [compoundDisposable dispose];
                          compoundDisposable = nil;
                      } completed:^{
                          yssert(NO, @"wtf happened");
                      }];

    miscDisposable = [RACDisposable disposableWithBlock:^{
        lllog(Error, @"[dispose] Disposing of subscription = SEFacebookSessionController -> self.isSignedIn");
    }];

    compoundDisposable = [RACCompoundDisposable compoundDisposableWithDisposables: @[ disposable, miscDisposable ]];
}


/**
 * handleOpenURL:
 *
 * @param {NSURL*} url
 */

- (BOOL) handleOpenURL: (NSURL *)url
{
    return [self.facebook handleOpenURL: url];
}



/**
 * signOut
 *
 * Logs the controller out of Facebook.
 */

- (void) signOut
{
    self.availablePermissions = @[];
    self.requestedPermissions = @[];

    [RACScheduler.scheduler schedule:^{
        [self.facebook logout];
    }];
}



#pragma mark-
#pragma mark-

- (void) videoRequestWithParams: (NSMutableDictionary *)params
                       delegate: (id)delegate
             requestObjectReady: (FBRequestObjectBlock)_requestObjectReady
{
    FBRequestObjectBlock requestObjectReady = [_requestObjectReady copy];

    @weakify(self);
    yssert_notNil(self.queue);
    dispatch_async(self.queue, ^{
        lllog(Warn, @"starting VIDEO REQUEST inside facebook session controller");
        @strongify(self);

        yssert_onMainThread();
        yssert_notNilAndIsClass(params, NSMutableDictionary);
        yssert_notNilAndConformsToProtocol(delegate, FBRequestDelegate);
        yssert_notNilAndIsClass(self.facebook, Facebook);


        FBRequest *request = [self.facebook requestWithGraphPath: @"me/videos"
                                                       andParams: params
                                                   andHttpMethod: @"POST"
                                                     andDelegate: delegate];
        lllog(Warn, @"after VIDEO REQUEST inside facebook session controller");

        yssert_notNilAndIsClass(request, FBRequest);

        lllog(Warn, @"detaching async operation for calling requestObjectReady VIDEO REQUEST inside facebook session controller");
        yssert_notNil(requestObjectReady);
        dispatch_async(dispatch_get_main_queue(), ^{
            lllog(Warn, @"[main threadddd] calling requestObjectReady VIDEO REQUEST inside facebook session controller (= %@, request = %@)", requestObjectReady, (request == nil ? @"NIL" : @"NOT NIL"));
            requestObjectReady(request);
        });
    });
}


- (void) didNotLogin
{
    lllog(Error, @"did not log into facebook.");
}



#pragma mark- FBSessionDelegate
#pragma mark-

- (void) fbDidLogin
{
    yssert_onMainThread();

    // logging
    lllog(Success, @"facebook login successful");

    // kvo
    self.isSignedIn = YES;
    self.availablePermissions = self.requestedPermissions;
}

- (void) fbDidExtendToken:(NSString *)accessToken
                expiresAt:(NSDate *)expiresAt
{
    yssert_onMainThread();

    // logging
    lllog(Success, @"did extend FB access token");

    // kvo
    self.isSignedIn = YES;
}

- (void) fbDidLogout
{
    yssert_onMainThread();

    // logging
    lllog(Success, @"facebook logout successful");

    // kvo
    self.isSignedIn = NO;
}

- (void)fbSessionInvalidated
{
    yssert_onMainThread();

    // logging
    lllog(Warn, @"facebook session invalidated");

    // kvo
    self.isSignedIn = NO;
}

- (void) fbDidNotLogin: (BOOL)cancelled
{
    yssert_onMainThread();

    // logging
    lllog(Warn, @"facebook did not log in (cancelled = %@)", @(cancelled));

    // kvo
    self.isSignedIn = NO;
}



@end
