//
//  SEFacebookUploadController.m
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>
#import "SEFacebookUploadController.h"
#import "SEFacebookSessionController.h"

@interface SEFacebookUploadController ()
    @property (nonatomic, strong, readwrite) FBRequest *facebookRequest;
    @property (nonatomic, strong, readwrite) NSURL	   *facebookPendingUploadVideoFileURL;
    @property (atomic,    strong, readwrite) NSError *error;
    @property (atomic,    assign, readwrite) Float32 progress;
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
    //
    // detach the facebook request delegate
    //
    if ((_facebookRequest != nil) && (_facebookRequest.delegate == self)) {
        _facebookRequest.delegate = nil;
        _facebookRequest		  = nil;
    }
}

- (void) doSignIn
{
    self.sessionController.requestedPermissions = @[ @"publish_stream" ];
    [super doSignIn];
}



/**
 * uploadVideo:
 *
 *
 */

- (void) doUploadVideo
{
    yssert_notNilAndIsClass(self.videoURL, NSURL);
    yssert_notNilAndIsClass(self.sessionController, SEFacebookSessionController);
    yssert_notNilAndIsClass(self.sessionController.facebook, Facebook);

    NSData *videoData = [NSData dataWithContentsOfURL: self.videoURL];
    NSMutableDictionary *params = @{@"video.mp4":   videoData,
                                    @"contentType": @"video/quicktime",
                                    @"title":       @"Video Test Title",
                                    @"description": @"Video Test Description", }.mutableCopy;

    self.facebookRequest = [self.sessionController.facebook requestWithGraphPath: @"me/videos"
                                                                       andParams: params
                                                                   andHttpMethod: @"POST"
                                                                     andDelegate: self];

    [super doUploadVideo];
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
    if ([result isKindOfClass: [NSArray class]]) {
        result = result[0];
    }

    [self complete];
}



/**
 * request:didFailWithError:
 */

- (void)	 request: (FBRequest *)request
    didFailWithError: (NSError *)error
{
    lllog(Error, @"Failed with error: %@", error.localizedDescription);
    [self failWithError:error];
}



@end
