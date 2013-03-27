//
//  SEFacebookUploadController.m
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>
#import <libextobjc/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SEFacebookUploadController.h"
#import "SEFacebookSessionController.h"

@interface SEFacebookUploadController ()
    @property (nonatomic, strong, readwrite) FBRequest *facebookRequest;
    @property (nonatomic, strong, readwrite) NSURL	   *facebookPendingUploadVideoFileURL;
    @property (nonatomic, strong, readwrite) NSError *error;
    @property (nonatomic, assign, readwrite) Float32 progress;
@end

@implementation SEFacebookUploadController

- (instancetype) initWithSessionController:(NSObject<SEUploadSessionController> *)sessionController
                                  videoURL:(NSURL *)videoURL
{
    yssert_notNilAndIsClass(sessionController, SEFacebookSessionController);
    self = [super initWithSessionController:sessionController videoURL:videoURL];
    if (self) {

    }
    return self;
}


/**
 * -dealloc
 *
 * @return {void}
 */

- (void) dealloc
{
    lllog(Warn, @"-[%@ dealloc] is being called", [self class]);

    //
    // detach the facebook request delegate
    //
    if ((_facebookRequest != nil) && (_facebookRequest.delegate == self)) {
        _facebookRequest.delegate = nil;
        _facebookRequest		  = nil;
    }
}

- (BOOL) sendsProgressUpdates
{
    return NO;
}


- (NSString *) serviceName
{
    return @"Facebook";
}


- (void) doSignIn
{
    @weakify(self);

    //    [RACScheduler.scheduler schedule:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        yssert_onMainThread();
        @strongify(self);

        [self.sessionController signInWithRequestedPermissions: @[ @"publish_stream" ]
                                                    completion: ^{
                                                        @strongify(self);

                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            @strongify(self);
                                                            yssert([self canFinishSigningIn], @"self cannot finishSigningIn");
                                                            lllog(Success, @"about to call -finishSigningIn");
                                                            [self finishSigningIn];
                                                        });
                                                    }];
    });
}




/**
 * uploadVideo:
 *
 *
 */

- (void) doUploadVideo
{
    [super doUploadVideo];

    yssert_notNilAndIsClass(self.videoURL, NSURL);
    yssert_notNilAndIsClass(self.sessionController, SEFacebookSessionController);
    yssert_notNilAndIsClass(self.sessionController.facebook, Facebook);

    NSData *videoData = [NSData dataWithContentsOfURL: self.videoURL];          yssert_notNilAndIsClass(videoData, NSData);
    NSMutableDictionary *params = @{@"video.mp4":   videoData,
                                    @"contentType": @"video/quicktime",
                                    @"title":       @"Money Money Video Maker",
                                    @"description": @"", }.mutableCopy;

    @weakify(self);
//    [RACScheduler.scheduler schedule:^{
//        @strongify(self);
//
//        yssert_notNilAndIsClass(self.videoURL, NSURL);
//        yssert_notNilAndIsClass(self.sessionController, SEFacebookSessionController);
//        yssert_notNilAndIsClass(self.sessionController.facebook, Facebook);

        [self.sessionController videoRequestWithParams: params
                                              delegate: self
                                    requestObjectReady:^(FBRequest *request) {
                                        @strongify(self);

                                        yssert(request.delegate == self, @"request.delegate == self");
                                        lllog(Info, COLOR_ORANGE(@"facebook request = %@"), (request == nil ? @"nil" : @"NOT NIL"));

                                        yssert_notNilAndIsClass(request, FBRequest);

                                        self.facebookRequest = request;
                                        lllog(Info, COLOR_ORANGE(@"facebook requestObjectReady = %@"), (self.facebookRequest == nil ? @"nil" : @"NOT NIL"));
                                    }];

//    }];
}



/**
 * -request:didLoad:
 *
 * @param {FBRequest*} request
 *
 * @return {void}
 */

- (void) request: (FBRequest *)request
         didLoad: (id)result
{
    lllog(Success, @"Succeeded with result: %@", result);

    if ([result isKindOfClass: [NSArray class]]) {
        result = result[0];
    }

    if (self.facebookRequest.delegate == self) {
        self.facebookRequest.delegate = nil;
    }
    self.facebookRequest = nil;

    @weakify(self);
    [RACScheduler.scheduler schedule:^{
        @strongify(self);
        yssert([self canComplete], @"self cannot complete");
        [self complete];
    }];
}



/**
 * request:didFailWithError:
 */

- (void)	 request: (FBRequest *)request
    didFailWithError: (NSError *)error
{
    lllog(Error, @"Failed with error: %@", error.localizedDescription);

    if (self.facebookRequest.delegate == self) {
        self.facebookRequest.delegate = nil;
    }
    self.facebookRequest = nil;

    @weakify(self);
    [RACScheduler.scheduler schedule:^{
        @strongify(self);
        yssert([self canFailWithError], @"self cannot failWithError");
        [self failWithError:error];
    }];
}



@end




