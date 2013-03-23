//
//  SEYouTubeUploadController.h
//  SEBeamMeUpScotty
//
//  Created by bryn austin bellomy on 3.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SEBeamMeUpScotty.h"
#import "SEUploadController.h"
#import "SEYouTubeSessionController.h"

@interface SEYouTubeUploadController : SEUploadController

@property (nonatomic, strong, readonly) SEYouTubeSessionController *sessionController;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) Float32 progress;

- (instancetype) initWithSessionController:(SEYouTubeSessionController *)sessionController videoURL:(NSURL *)videoURL;

// @@TODO:
//- (void) restartUpload;

@end







