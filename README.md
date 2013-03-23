
# // beam me up, scotty

starfleet-grade iOS video uploads.

# installing

Use [CocoaPods](http://cocoapods.org).

In your Podfile:

```ruby
pod 'SEBeamMeUpScotty'
```

Then back in the shell:

```shell
$ pod install
```

# how to use ([here's a longer example](https://github.com/brynbellomy/SEBeamMeUpScotty/blob/master/ReallyTerseExample.m))

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

Some session controllers can auto-login from the keychain if the user has logged in before.  Others can't.

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



# contributors

- bryn austin bellomy < <bryn@signals.io> >



# license (WTFPL)

```text
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE  
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified 
copies of this license document, and changing it is allowed as long 
as the name is changed. 

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO. 
```


