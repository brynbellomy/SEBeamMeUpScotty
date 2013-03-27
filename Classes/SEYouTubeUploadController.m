//
//  SEYouTubeUploadController.m
//  Stan
//
//  Created by bryn austin bellomy on 3.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <BrynKit/RACSubject+SERACHelpers.h>

#import <libextobjc/EXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import <iOS-GTLYouTube/GTLYouTubeConstants.h>
#import <iOS-GTLYouTube/GTLYouTube.h>
#import <iOS-GTLYouTube/GTLService.h>
#import <iOS-GTLYouTube/GTMHTTPUploadFetcher.h>

#import "SEYouTubeSessionController.h"
#import "SEYouTubeUploadController.h"

@interface SEYouTubeUploadController ()

@property (nonatomic, strong, readwrite) SEYouTubeSessionController *sessionController;

@property (nonatomic, strong, readwrite) NSURL            *uploadLocationURL;   // url for restarting a YouTube upload
@property (nonatomic, strong, readwrite) GTLServiceTicket *uploadFileTicket;
@property (nonatomic, strong, readwrite) NSURL            *youTubePendingUploadVideoFileURL;

@property (nonatomic, strong, readwrite) NSError          *error;
@property (nonatomic, assign, readwrite) Float32          progress;

@end

@implementation SEYouTubeUploadController



- (instancetype) initWithSessionController:(NSObject<SEUploadSessionController> *)sessionController
                                  videoURL:(NSURL *)videoURL
{
    yssert_notNilAndIsClass(sessionController, SEYouTubeSessionController);
    self = [super initWithSessionController:sessionController videoURL:videoURL];
    if (self)
    {
    }
    return self;
}

- (void) dealloc
{
    lllog(Warn, @"-[%@ dealloc] is being called", [self class]);
}


- (BOOL) sendsProgressUpdates
{
    return YES;
}

- (NSString *) serviceName
{
    return @"YouTube";
}



/**
 * uploadVideo:
 *
 *
 */

- (void) doUploadVideo
{
    [super doUploadVideo];

    lllog(Info, @"self.videoURL = %@", self.videoURL);

    // Collect the metadata for the upload from the user interface.

    // privacy setting
    GTLYouTubeVideoStatus *status = [GTLYouTubeVideoStatus object];
    status.privacyStatus = SEUploadYouTubePrivacySetting_Public; // @@TODO

    // Snippet.
    GTLYouTubeVideoSnippet *snippet = [GTLYouTubeVideoSnippet object];
    snippet.title = $str(@"Money Money Video Maker (%@)", [NSDate date]);
    snippet.descriptionProperty = @"(no description)";
    //    NSString *tagsStr = [_uploadTagsField stringValue];
    //    if ([tagsStr length] > 0) {
    //        snippet.tags = [tagsStr componentsSeparatedByString:@","];
    //    }
    snippet.tags = @[@"money", @"music video", @"hilarious"];

    //    if ([_uploadCategoryPopup isEnabled]) {
    //        NSMenuItem *selectedCategory = [_uploadCategoryPopup selectedItem];
    //        snippet.categoryId = [selectedCategory representedObject];
    //    }

    GTLYouTubeVideo *video = [GTLYouTubeVideo object];              yssert_notNilAndIsClass(video, GTLYouTubeVideo);
    video.status  = status;
    video.snippet = snippet;

    [self uploadVideoToYouTubeFromFileURL: self.videoURL
                              videoObject: video
                  resumeUploadLocationURL: nil];
}



/**
 * restartUpload
 *
 * @@TODO
 */

//- (void) restartUpload
//{
//    // Restart a stopped upload, using the location URL from the previous
//    // upload attempt
//    if ((self.uploadLocationURL == nil) || (self.youTubePendingUploadVideoFileURL == nil)) {
//        return;
//    }
//
//    self.status = SEUploadStatus_InProgress;
//
//    // Since we are restarting an upload, we do not need to add metadata to the
//    // video object.
//    GTLYouTubeVideo *video = [GTLYouTubeVideo object];              yssert_notNilAndIsClass(video, GTLYouTubeVideo);
//
//    [self uploadVideoToYouTubeFromFileURL: self.youTubePendingUploadVideoFileURL
//                              videoObject: video
//                  resumeUploadLocationURL: self.uploadLocationURL];
//}



/**
 * uploadVideoToYouTubeFromFileURL:videoObject:resumeUploadLocationURL:
 *
 *
 */

- (void) uploadVideoToYouTubeFromFileURL: (NSURL *)videoFileURL
                             videoObject: (GTLYouTubeVideo *)video
                 resumeUploadLocationURL: (NSURL *)locationURL
{
    if (self.sessionController.isSignedIn != YES) {
        lllog(Error, @"Not logged in!");
        return;
    }

    yssert(self.sessionController.isSignedIn == YES, @"Must be signed in!");
    yssert_notNilAndIsClass(self.sessionController.youTubeService, GTLServiceYouTube);
    yssert_notNilAndIsClass(videoFileURL, NSURL);
    yssert_notNilAndIsClass(video, GTLYouTubeVideo);

    @weakify(self);

    self.youTubePendingUploadVideoFileURL = videoFileURL;

    // Get a file handle for the upload data.
    NSError      *error      = nil;
    NSString     *filename   = self.youTubePendingUploadVideoFileURL.lastPathComponent;                                         yssert_notNilAndIsClass(filename,   NSString);
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:self.youTubePendingUploadVideoFileURL error:&error];   yssert_notNilAndIsClass(fileHandle, NSFileHandle);

    if (error != nil)
    {
        [self failWithError:error];
        return;
    }

    if (fileHandle == nil)
    {
        NSError *error = [NSError errorWithDomain:@"com.signalenvelope.YouTubeUploadController" code:1 userInfo:@{ @"message": @"Couldn't find video to upload." }];
        [self failWithError: error];
        return;
    }

    NSString            *mimeType         = [self MIMETypeForFilename:filename defaultMIMEType:@"video/mp4"];                      yssert_notNilAndIsClass(mimeType, NSString);
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithFileHandle:fileHandle MIMEType:mimeType];     yssert_notNilAndIsClass(uploadParameters, GTLUploadParameters);
    uploadParameters.uploadLocationURL    = locationURL;

    GTLQueryYouTube     *query            = [GTLQueryYouTube queryForVideosInsertWithObject:video part:@"snippet,status" uploadParameters:uploadParameters];        yssert_notNilAndIsClass(query, GTLQueryYouTube);

    //
    // fire off the request
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);

        yssert_notNilAndIsClass(self.sessionController.youTubeService, GTLServiceYouTube);
        self.uploadFileTicket = [self.sessionController.youTubeService executeQuery: query
                                                                  completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideo *uploadedVideo, NSError *error) {

                                                                      @strongify(self);

                                                                  [[RACScheduler mainThreadScheduler] schedule:^{
                                                                          @strongify(self);

                                                                          self.uploadFileTicket  = nil;
                                                                          self.uploadLocationURL = nil;

                                                                          if (error)
                                                                          {
                                                                              lllog(Error, @"YouTube upload failed = { localizedDescription:'%@', localizedFailureReason: '%@' }", error.localizedDescription, error.localizedFailureReason);
                                                                              [self failWithError: error];
                                                                              return;
                                                                          }

                                                                          [self complete];
                                                                      }];
                                                                  }];

        yssert_notNilAndIsClass(self.uploadFileTicket, GTLServiceTicket);

        self.uploadFileTicket.uploadProgressBlock = ^(GTLServiceTicket *ticket, unsigned long long numberOfBytesRead, unsigned long long dataLength) {
            @strongify(self);

            [[RACScheduler mainThreadScheduler] schedule:^{
                @strongify(self);
                self.progress = (Float32)((float)numberOfBytesRead / (float)dataLength);
            }];
        };

        yssert_notNil(self.uploadFileTicket.uploadProgressBlock);


        //
        // to allow restarting after stopping, we need to track the upload location url
        //
        GTMHTTPUploadFetcher *uploadFetcher = (GTMHTTPUploadFetcher *)self.uploadFileTicket.objectFetcher;          yssert_notNilAndIsClass(uploadFetcher, GTMHTTPUploadFetcher);
        uploadFetcher.locationChangeBlock = ^(NSURL *url) {
            @strongify(self);
            self.uploadLocationURL = url;
        };
    });
}



/**
 * MIMETypeForFilename:defaultMIMEType:
 *
 *
 */

- (NSString *) MIMETypeForFilename: (NSString *)filename
                   defaultMIMEType: (NSString *)defaultType
{
    NSString   *result    = defaultType;
    NSString   *extension = [filename pathExtension];
    CFStringRef uti       = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);

    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);

        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }

        CFRelease(uti);
    }

    return result;
}


@end
