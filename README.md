
# // beam me up, scotty <div style="font-size: 12px">starfleet grade iOS video uploads</div>

Initialize the session controller.

```objective-c
SEFacebookSessionController *facebookSessionController
    = [[SEFacebookSessionController alloc] initAppID:kAppID];

SEYouTubeSessionController *youtubeSessionController
    = [[SEYouTubeSessionController alloc]
            initWithKeychainItemName:kKeychainItemName
                            clientID:kYouTubeClientID
                        clientSecret:kYouTubeClientSecret];
```

Prepare the upload controller.

```objective-c
NSURL *videoFileURL = ... ;

SEFacebookUploadController *facebookUploadController
    = [facebookSessionController uploadControllerForVideoFileURL: videoFileURL];

SEYouTubeUploadController *youtubeUploadController
    = [youtubeSessionController uploadControllerForVideoFileURL: videoFileURL];
```

Some session controllers can auto-login from the keychain if the user has logged in before.

```objective-c
assert(facebookSessionController.isSignedIn == YES or NO);
assert(youtubeSessionController.isSignedIn == NO);
```

Use [ReactiveCocoa](http://github.com/ReactiveCocoa/ReactiveCocoa) to observe the properties that you need to respond to.

```objective-c
// disable the upload button when the user is signed out
RAC(self.uploadButton.enabled) =
   RACAbleWithStart(facebookSessionController, isSignedIn);

// dim the upload button when the user is signed out
RAC(self.uploadButton.alpha) =
    [RACAbleWithStart(facebookSessionController, isSignedIn)
        map:^id (NSNumber *isSignedIn) {
            if (isSignedIn.boolValue == YES)
                return @1.0f;
            else
                return @0.4f
        }];
```


# an extended example

```objective-c
@weakify(self);

NSURL *videoFileURL = ... ; // or whatever

//
// initialize our session controllers
//
self.facebookSessionController =
    [[SEFacebookSessionController alloc] initAppID:kAppID];

self.youtubeSessionController =
    [[SEYouTubeSessionController alloc] initWithKeychainItemName:kKeychainItemName
                                                        clientID:kYouTubeClientID
                                                    clientSecret:kYouTubeClientSecret];

//
// initialize our upload controllers (single use)
//
SEFacebookUploadController *facebookUploadController =
    [facebookSessionController uploadControllerForVideoFileURL: videoFileURL];

SEYouTubeUploadController *youtubeUploadController =
    [youtubeSessionController uploadControllerForVideoFileURL: videoFileURL];

assert(facebookSessionController.isSignedIn == YES or NO);
assert(youtubeSessionController.isSignedIn == NO);

//
// observe the session and upload controllers and
// update the login/upload flow and the ui accordingly
//

// disable the upload button when the user is signed out
RAC(self.uploadButton.enabled) =
   RACAbleWithStart(facebookSessionController, isSignedIn);

// dim the upload button when the user is signed out
RAC(self.uploadButton.alpha) =
    [RACAbleWithStart(facebookSessionController, isSignedIn)
        map:^id (NSNumber *isSignedIn) {
            if (isSignedIn.boolValue == YES)
                return @1.0f;
            else
                return @0.4f
        }];

RACDisposable *uploadProgressWatcherDisposable = nil;
RACDisposable *uploadStatusDisposable = nil;
__block RACCompoundDisposable *compoundDisposable = nil;
__block SEUploadController *uploadController = nil;

// update the progress indicator on an MBProgressHUD
// with the 'percent completed' value
uploadProgressWatcherDisposable =
        [[RACAbleWithStart(uploadController, progress)
                deliverOn: RACScheduler.mainThreadScheduler]
                subscribeNext:^(NSNumber *numProgress) {
                     @strongify(self);

                     float progress = numProgress.floatValue;
                     [MBProgressHUD threadsafeShowHUDOnView:self.view
                                                   setupHUD:^(MBProgressHUD *hud) {
                                                       hud.progress = progress;
                                                   }];
                }];


// this subscription to the upload controller's current state is responsible
// for firing certain methods (for signing in, starting the upload, etc.)
// and performing a couple of ui updates.
//
// notice in particular that the creation of this subscription is responsible
// for kicking off the upload process all by itself.
uploadStatusDisposable =
        [[RACAbleWithStart(self.uploadController, state)
                deliverOn: RACScheduler.mainThreadScheduler]
                subscribeNext:^(NSString *uploadState) {

    @strongify(self);

    // show sign-in view controller if user needs to sign in
    if ([uploadState isEqualToString: SEUploadState_NotLoggedIn])
        [self.uploadController signIn];

    // automatically start upload once ready
    else if ([uploadState isEqualToString: SEUploadState_ReadyToUpload])
        [self.uploadController uploadVideo];

    // set up the upload progress observer
    else if ([uploadState isEqualToString: SEUploadState_InProgress])
    {
        [MBProgressHUD threadsafeShowHUDOnView:self.view
                                      setupHUD:^(MBProgressHUD *hud) {
                                          hud.labelText = @"Uploading to YouTube...";
                                      }];
    }

    // when complete, show a notice to the user
    else if ([uploadState isEqualToString: SEUploadState_Complete])
    {
        [MBProgressHUD threadsafeShowHUDOnView: self.view
                                      setupHUD:^(MBProgressHUD *hud) {
                                          hud.labelText        = @"Video uploaded!";
                                          [hud hide: YES afterDelay: 4.0f];
                                      }];

        [compoundDisposable dispose];
        compoundDisposable = nil;
        uploadController = nil;
    }

    // handle errors
    else if ([uploadState isEqualToString: SEUploadState_Error])
    {
        [MBProgressHUD threadsafeShowHUDOnView: self.view
                                      setupHUD:^(MBProgressHUD *hud) {
                                          hud.labelText        = @"Upload failed.";
                                          [hud hide: YES afterDelay: 4.0f];
                                      }];

        [compoundDisposable dispose];
        compoundDisposable = nil;
        uploadController = nil;
    }
    else {
        lllog(Warn, @"unknown upload state = %@", uploadState);
    }
}];
```



