//
//  SEFacebookSessionController.m
//  Stan
//
//  Created by bryn austin bellomy on 3.16.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Facebook-iOS-SDK/FacebookSDK/Facebook.h>
#import <BrynKit/BrynKitCocoaLumberjack.h>
#import <libextobjc/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "SEFacebookSessionController.h"
#import "SEFacebookUploadController.h"
#import "SEUpload.h"

@interface SEFacebookSessionController ()
    @property (nonatomic, strong, readwrite) Facebook *facebook;
    @property (nonatomic, strong, readwrite) NSArray *availablePermissions;
    @property (nonatomic, strong, readwrite) NSError *error;
    @property (nonatomic, assign, readwrite) BOOL isSignedIn;
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
    self = [super init];
    if (self) {
        _error = nil;
        _facebook = [[Facebook alloc] initWithAppId:appID andDelegate:self];
    }
    return self;
}


- (SEFacebookUploadController *) uploadControllerForVideoFileURL:(NSURL *)videoFileURL
{
    return [[SEFacebookUploadController alloc] initWithSessionController:self videoURL:videoFileURL];
}



- (void) signInWithRequestedPermissions:(NSArray *)permissions
                             completion:(dispatch_block_t)completion
{
    self.requestedPermissions = [permissions copy];
    [self signInWithCompletion:completion];

}

- (void) signInWithCompletion:(dispatch_block_t)completion
{
    yssert_notNilAndIsClass(self.requestedPermissions, NSArray);
    @weakify(self);

    self.isSignedIn = NO;
    self.availablePermissions = @[];

    __block RACDisposable *disposable = nil;
    disposable = [[RACAbleWithStart(self.isSignedIn)
                      distinctUntilChanged]
                      subscribeNext:^(NSNumber *isLoggedIn) {
                          @strongify(self);

                          lllog(Verbose, @"self.sessionController.isSignedIn <next> = %@", isLoggedIn);
                          if (isLoggedIn.boolValue == YES)
                          {
                              [disposable dispose];
                              disposable = nil;
                              completion();
                          }
                          else
                          {
                              yssert_notNilAndIsClass(self.requestedPermissions, NSArray);
                              [self.facebook authorize:self.requestedPermissions];
                          }

                      }
                      error:^(NSError *error) {
                          @strongify(self);

                          [disposable dispose];
                          self.error = error;
                          self.isSignedIn = NO;

                          completion();
                      }];
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

    [self.facebook logout];
}



#pragma mark- FBSessionDelegate
#pragma mark-

- (void) fbDidLogin
{
    // logging
    lllog(Success, @"facebook login successful");

    // kvo
    self.isSignedIn = YES;
    self.availablePermissions = self.requestedPermissions;
}

- (void) fbDidExtendToken:(NSString *)accessToken
                expiresAt:(NSDate *)expiresAt
{
    // logging
    lllog(Success, @"did extend FB access token");

    // kvo
    self.isSignedIn = YES;
}

- (void) fbDidLogout
{
    // logging
    lllog(Success, @"facebook logout successful");

    // kvo
    self.isSignedIn = NO;
}

- (void)fbSessionInvalidated
{
    // logging
    lllog(Warn, @"facebook session invalidated");

    // kvo
    self.isSignedIn = NO;
}

- (void) fbDidNotLogin: (BOOL)cancelled
{
    // logging
    lllog(Warn, @"facebook did not log in (cancelled = %@)", @(cancelled));

    // kvo
    self.isSignedIn = NO;
}



@end
