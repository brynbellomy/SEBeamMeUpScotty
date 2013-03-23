//
//  SEYouTubeSessionController.m
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.18.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <iOS-GTLYouTube/GTMOAuth2ViewControllerTouch.h>
#import <iOS-GTLYouTube/GTLYouTubeConstants.h>
#import <iOS-GTLYouTube/GTLYouTube.h>
#import <iOS-GTLYouTube/GTLService.h>
#import <iOS-GTLYouTube/GTMHTTPUploadFetcher.h>
#import <iOS-GTLYouTube/GTLServiceYouTube.h>

#import <libextobjc/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <BrynKit/BrynKit.h>

#import "SEYouTubeSessionController.h"
#import "SEYouTubeUploadController.h"

@interface SEYouTubeSessionController ()

@property (nonatomic, strong, readwrite) GTLServiceYouTube            *youTubeService;
@property (nonatomic, strong, readwrite) GTMOAuth2Authentication      *youTubeAuthentication;
@property (nonatomic, strong, readwrite) NSString                     *youTubeSignedInUsername;
@property (nonatomic, assign, readwrite) BOOL                          isSignedIn;
@property (nonatomic, strong, readwrite) NSError                      *error;

@property (nonatomic, strong, readwrite) NSString *keychainItemName;
@property (nonatomic, strong, readwrite) NSString *clientID;
@property (nonatomic, strong, readwrite) NSString *clientSecret;


@end

@implementation SEYouTubeSessionController


- (instancetype) init
{
    @throw [NSException exceptionWithName:@"NSInternalInconsistencyException" reason:@"You must call -[SEYouTubeSessionController initWithKeychainItemName:clientID:clientSecret:], the designated initializer." userInfo:nil];
    self = nil;
    return nil;
}


- (instancetype) initWithKeychainItemName:(NSString *)keychainItemName
                                 clientID:(NSString *)clientID
                             clientSecret:(NSString *)clientSecret
{
    yssert_notNilAndIsClass(keychainItemName, NSString);
    yssert_notNilAndIsClass(clientID,         NSString);
    yssert_notNilAndIsClass(clientSecret,     NSString);

    self = [super init];
    if (self)
    {
        _keychainItemName = keychainItemName;
        _clientID = clientID;
        _clientSecret = clientSecret;

        [self initializeReactiveKVO];
    }
    return self;
}


- (void) initializeReactiveKVO
{
    //
    // Returns the email address of the signed-in user or nil if not authenticated.
    //
    RAC(self.youTubeSignedInUsername) = [[[RACAbleWithStart(self.youTubeAuthentication.canAuthorize)
                                               distinctUntilChanged]
                                               filter:^BOOL(id value) { return (value != nil); }]
                                               map:^id (NSNumber *canAuthorize) {
                                                   return (canAuthorize.boolValue == YES
                                                               ? self.youTubeAuthentication.userEmail
                                                               : RACTupleNil.tupleNil);
                                               }];

    RAC(self.isSignedIn) = [RACAbleWithStart(self.youTubeSignedInUsername)
                                map:^id (NSString *youTubeSignedInUsername) {
                                    return @( self.youTubeSignedInUsername != nil );
                                }];


    RACBind(self.youTubeService.authorizer) = RACBind(self.youTubeAuthentication);

    [RACAbleWithStart(self.isSignedIn)
        subscribeNext:^(NSNumber *isSignedIn) {
            if (isSignedIn.boolValue == NO) {
                [self attemptYouTubeSignInFromSavedKeychainItem];
            }
        }];
}



- (SEYouTubeUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL
{
    return [[SEYouTubeUploadController alloc] initWithSessionController:self videoURL:videoFileURL];
}



/**
 * youTubeService
 *
 *
 */

- (GTLServiceYouTube *) youTubeService
{
    if (_youTubeService == nil)
    {
        _youTubeService = $new(GTLServiceYouTube);

        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        _youTubeService.shouldFetchNextPages = YES;

        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        _youTubeService.retryEnabled = YES;
    }
    return _youTubeService;
}



/**
 * -signInWithCompletion:
 *
 * @return {UIViewController*} The YouTube sign in view controller, if one must be used to log the user in.  Push this onto your current navigation controller's hierarchy.
 */
- (void) signInWithCompletion:(dispatch_block_t)completion
{
    if (self.isSignedIn)
    {
        if (completion != nil)
            completion();

        lllog(Info, @"Already logged into YouTube.");
        return;
    }

    else if ([self attemptYouTubeSignInFromSavedKeychainItem] == YES)
    {
        yssert(self.isSignedIn == YES, @"self.signedIn should be TRUE after successfully calling -attemptYouTubeSignInFromSavedKeychainItem.");

        if (completion != nil)
            completion();

        return;
    }

//    UIViewController *viewController =
    [self signInViewControllerWithCompletion:completion];
//    yssert_notNilAndIsClass(viewController, UIViewController);

//    return viewController;
}


/**
 * didSignInToYouTube
 *
 *
 */

- (void) didSignInToYouTube
{
    self.isSignedIn = YES;
}



/**
 * didNotSignInToYouTube:
 *
 * @param {NSError*} error
 */
- (void) didNotSignInToYouTube:(NSError *)error
{
    self.error      = error;
    self.isSignedIn = NO;
    self.youTubeAuthentication = nil;
}


/**
 * attemptYouTubeSignInFromSavedKeychainItem
 *
 *
 */

- (BOOL) attemptYouTubeSignInFromSavedKeychainItem
{
    yssert_notNilAndIsClass(self.keychainItemName, NSString);
    yssert_notNilAndIsClass(self.clientID, NSString);
    yssert_notNilAndIsClass(self.clientSecret, NSString);

    // Get the saved authentication, if any, from the keychain.
    self.youTubeAuthentication = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName: self.keychainItemName
                                                                                       clientID: self.clientID
                                                                                   clientSecret: self.clientSecret];

    if (self.youTubeAuthentication.canAuthorize) {
        [self didSignInToYouTube];
        return YES;
    }
    else {
        // don't call `-didNotSignInToYouTube` here -- this method is
        // intended to offer a silent, non-critical "background login" path
        return NO;
    }
}



/**
 * showYouTubeSignInViewThenHandler:
 *
 *
 */

- (GTMOAuth2ViewControllerTouch *) signInViewControllerWithCompletion:(dispatch_block_t) completionHandler
{
    yssert_notNilAndIsClass(self.keychainItemName, NSString);
    yssert_notNilAndIsClass(self.clientID, NSString);
    yssert_notNilAndIsClass(self.clientSecret, NSString);

    // Show the OAuth 2 sign-in controller.
    @weakify(self);
    GTMOAuth2ViewControllerTouch *youtubeVC = [GTMOAuth2ViewControllerTouch controllerWithScope: kGTLAuthScopeYouTube
                                                                                       clientID: self.clientID
                                                                                   clientSecret: self.clientSecret
                                                                               keychainItemName: self.keychainItemName
                                                                              completionHandler:^(GTMOAuth2ViewControllerTouch *vc, GTMOAuth2Authentication *auth, NSError *error) {
                                                                                  @strongify(self);

                                                                                  if (error != nil) {
                                                                                      lllog(Error, @"Error signing into YouTube = %@", error.localizedDescription);
                                                                                      [self didNotSignInToYouTube: error];
                                                                                      return;
                                                                                  }

                                                                                  self.youTubeAuthentication = auth;

                                                                                  if (auth.canAuthorize) {
                                                                                      [self didSignInToYouTube];
                                                                                  }

                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      [youtubeVC.navigationController popViewControllerAnimated:YES];
                                                                                  });

                                                                                  if (completionHandler != nil) {
                                                                                      [RACScheduler.mainThreadScheduler schedule:completionHandler];
                                                                                  }
                                                                              }];

    yssert_notNilAndIsClass(youtubeVC, GTMOAuth2ViewControllerTouch);

    // @@TODO: haven't made sure this works yet
    [[[UIApplication sharedApplication] delegate].window.rootViewController.navigationController pushViewController:youtubeVC animated:YES];

    return youtubeVC;
}



/**
 * signOut
 *
 *
 */

- (void) signOut
{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName: self.keychainItemName];
    self.youTubeService.authorizer = nil;
    self.youTubeAuthentication     = nil;
    self.isSignedIn = NO;
}




@end







