//
//  SEFacebookUploadController.h
//  Stan
//
//  Created by bryn austin bellomy on 3.15.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SEUpload.h"
#import "SEUploadController.h"
#import "SEFacebookSessionController.h"

@interface SEFacebookUploadController : SEUploadController <FBRequestDelegate>

@property (nonatomic, strong, readonly) SEFacebookSessionController *sessionController;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) Float32 progress;

- (instancetype) initWithSessionController:(SEFacebookSessionController *)sessionController videoURL:(NSURL *)videoURL;

@end





