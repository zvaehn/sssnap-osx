//
//  AppDelegate.m
//  sssnap
//
//  Created by Sven Schiffer 30.05.2014
//  Copyright (c) 2014 AwesomePeople. All rights reserved.
//

#import "AppDelegate.h"
#import "sendPost.h"
#import <Carbon/Carbon.h>

@implementation AppDelegate{

}

@synthesize statusBar = _statusBar;


- (void)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    // Enter is pressed, so proceed the login
    if (commandSelector == @selector(insertNewline:)) {
        [self proceedLogin];
    }
    else if (commandSelector == @selector(deleteForward:)) {
        //Do something against DELETE key
    }
    else if (commandSelector == @selector(deleteBackward:)) {
        //Do something against BACKSPACE key
    }
    else if (commandSelector == @selector(insertTab:)) {
        //Do something against TAB key
    }
}

//
//  All code in here is executed immediately after the
//  application has finished loading.
//
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_signInErrorLabel setStringValue:[NSString stringWithFormat:@"%@", @""]];
    
    // User is logged out
    if(![[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] count]){
        NSLog(@"AccountStore is empty.");
        
        [_signInErrorLabel setHidden: YES];
        [_preferences setEnabled: NO];
        [_takeScreenshotMenuItem setEnabled: NO];
        [_mySnapsItem setEnabled: NO];
        [_signInWindow makeKeyAndOrderFront:_signInWindow];
        [NSApp activateIgnoringOtherApps:YES];
        [_label_accountmail setStringValue: @"unknown"];
        [_createAccountItem setHidden: NO];
        
        self.passwordInput.delegate = self;
        self.statusBar.image = [NSImage imageNamed: @"icon-disabled"];
    }
    // User is logged in
    else {
        NSLog(@"Found %lu Account(s) in Auth2AccountStore.", [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] count]);
        
        [_signIn setHidden: YES];
        
        [_preferences setEnabled: YES];
        [_takeScreenshotMenuItem setEnabled: YES];
        [_mySnapsItem setEnabled: YES];
        [_createAccountItem setHidden: YES];
        
        [_signInWindow close];
    
        //NSLog(@"%@", [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] lastObject]);
        
        [_label_accountmail setStringValue: @"known"];
        
        self.statusBar.image = [NSImage imageNamed: @"icon"];
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate: self];
}

- (void) proceedLogin {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    
    [[NXOAuth2AccountStore sharedStore] setClientID:@"testid"
                                             secret:@"testsecret"
                                   authorizationURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/api/oauth/token", infoDict[@"serverurl"]]]
                                           tokenURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/api/oauth/token", infoDict[@"serverurl"]]]
                                        redirectURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@", infoDict[@"serverurl"]]]
                                     forAccountType:@"password"];
    
    [[NXOAuth2AccountStore sharedStore] setTrustModeHandlerForAccountType:@"password" block:^NXOAuth2TrustMode(NXOAuth2Connection *connection, NSString *hostname) {
        return NXOAuth2TrustModeAnyCertificate;
    }];
    
    NSString *username = [_usernameInput stringValue];  // get username by login-form
    NSString *password = [_passwordInput stringValue];  // get password by login-form
    
    // Request access
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"password" username:username password:password];
    
    // On Sucess
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification) {
                                                      [_signIn setHidden: YES];
                                                      [_createAccountItem setHidden: YES];
                                                      
                                                      [_mySnapsItem setEnabled: YES];
                                                      [_preferences setEnabled: YES];
                                                      [_takeScreenshotMenuItem setEnabled:YES];
                                                      
                                                      [_signInWindow close];
                                                      self.statusBar.image = [NSImage imageNamed: @"icon"];
                                                      
                                                      // Set the default Values
                                                      NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
                                                      [userPreferences setBool: YES forKey: @"copyLinkToClipboard"];
                                                      [userPreferences setBool: YES forKey: @"downscaleRetinaScreenshots"];
                                                      [userPreferences setBool: YES forKey: @"showDesktopNotifications"];
                                                      [userPreferences setObject: username forKey: @"current_user"];
                                                      [userPreferences synchronize];
                                                      
                                                      NSLog(@"Successfully logged in.");
                                                  }];
    
    // On Failure
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification) {
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      [_signInErrorLabel setHidden: NO];
                                                      [_signInErrorLabel setStringValue: [NSString stringWithFormat: @"%@", [error localizedDescription]]];
                                                      
                                                      NSLog(@"Failed to login: \n%@", error);
                                                  }];
}

- (IBAction)takeScreenshotItem:(id)sender {
    [AppDelegate takeScreenshot];
}

- (IBAction)signIn:(id)sender {
    [self proceedLogin];
}

// Is called when the Menu is opened
- (void)menuWillOpen:(NSMenu *)menu {
        
    // Get the recent snaps
    [[[sendPost alloc] init] getRecentSnaps];
}

- (void) menuDidClose:(NSMenu *)menu {
    // It's doing nothing atm. ZzZzzz...
}

- (IBAction)mySnapsItem:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://51seven.de:8888/snap/list"]];
}

- (IBAction)createAccountItem:(id)sender {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[NSString stringWithFormat: @"%@/user/register", infoDict[@"serverurl"]]]];
}

- (IBAction)preferencesMenuItemClick:(id)sender {
    
    // Loading User Preferences from .plist-file
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    
    // Setting the Toolbar defaultitem to active
    [_preferencesToolbar setSelectedItemIdentifier:@"GeneralPreferences"];
    
    // Removing all subviews and setting the default View
    for (int i = (int)_preferencesWrapperView.subviews.count-1; i >= 0; i--) {
        [[_preferencesWrapperView.subviews objectAtIndex:i] removeFromSuperview];
    }
    
    [_preferencesWrapperView addSubview: _preferencesGeneralView];
    
    // Setting the Gravatar Image
    NSString *gravatar_user = [NSString stringWithFormat: @"%@", [userPreferences stringForKey: @"current_user"]];
    gravatar_user = [functions md5: [[gravatar_user lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]]; // Generating Gravatar Hash
    
    // Download the image thumbnail
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       NSURL *imageURL = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.gravatar.com/avatar/%@?s=128", gravatar_user]];
                       NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                       NSImage *gravatar_image = [[NSImage alloc] initWithData:imageData];
                       
                       //This is your completion handler
                       dispatch_sync(dispatch_get_main_queue(), ^{
                           [_userAvatar setImage: gravatar_image];
                       });
                   });
    
    // Preparing ShowDesktopNotification Checkbox
    ([userPreferences boolForKey: @"showDesktopNotifications"]) ? [_pref_showDesktopNotification setState: 1] : [_pref_showDesktopNotification setState: 0];
    
    // Preparing Startup Checkbox
    ([self appIsLoginItem]) ? [_preferencesStartupCheckbox setState:1] : [_preferencesStartupCheckbox setState:0];
    
    // Preparing DownscaleRetinaScreenshots Checkbox
    ([userPreferences boolForKey: @"downscaleRetinaScreenshots"]) ? [_pref_retinaScale setState: 1] : [_pref_retinaScale setState: 0];

    // Preparing CopyLinkToClipboard Checkbox
    ([userPreferences boolForKey: @"copyLinkToClipboard"]) ? [_pref_CopyLinkToClipboard setState: 1] : [_pref_CopyLinkToClipboard setState: 0];
    
    // Settings the Account
    [_label_accountmail setStringValue: [NSString stringWithFormat: @"%@", [userPreferences stringForKey: @"current_user"]]];
    
    //Open the preferences Window
    [_preferencesWindow makeKeyAndOrderFront:_preferencesWindow];
    [_preferencesWindow setOrderedIndex:0];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)logoutButton:(id)sender {
    
    // Remove all accounts from the keychain
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        [[NXOAuth2AccountStore sharedStore] removeAccount: account];
    };
    
    // Changing Interface
    [_preferences setEnabled: NO];
    [_takeScreenshotMenuItem setEnabled: NO];
    [_signIn setHidden: NO];
    [_mySnapsItem setEnabled: NO];
    
    [_createAccountItem setHidden: NO];
    
    [_usernameInput setStringValue: @""];
    [_passwordInput setStringValue: @""];
    
    self.statusBar.image = [NSImage imageNamed: @"icon-disabled"];
    
    [_preferencesWindow close];
    
    // Deleting User-Settings from NSUserDefaults
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    NSDictionary * userPrefDict = [userPreferences dictionaryRepresentation];
    
    for (id key in userPrefDict) {
        [userPreferences removeObjectForKey:key];
    }
    
    [userPreferences synchronize];
    
    NSLog(@"User was successfully logged out.");
}

- (IBAction)signInMenuItemClick:(id)sender {
    [_signInWindow makeKeyAndOrderFront:_signInWindow];
    [_signInWindow setOrderedIndex:0];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)pref_retinaScale:(id)sender {

    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    
    if([userPreferences boolForKey: @"downscaleRetinaScreenshots"]) {
        [userPreferences setBool: NO forKey: @"downscaleRetinaScreenshots"];
    }
    else {
        [userPreferences setBool: YES forKey: @"downscaleRetinaScreenshots"];
    }
    
    [userPreferences synchronize];
}

- (IBAction)pref_showDesktopNotification:(id)sender {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    
    if([userPreferences boolForKey: @"showDesktopNotifications"]) {
        [userPreferences setBool: NO forKey: @"showDesktopNotifications"];
    }
    else {
        [userPreferences setBool: YES forKey: @"showDesktopNotifications"];
    }
    
    [userPreferences synchronize];
}

- (IBAction)pref_CopyLinkToClipboard:(id)sender {
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    
    if([userPreferences boolForKey: @"copyLinkToClipboard"]) {
        [userPreferences setBool: NO forKey: @"copyLinkToClipboard"];
    }
    else {
        [userPreferences setBool: YES forKey: @"copyLinkToClipboard"];
    }
    
    [userPreferences synchronize];
}

//This is execute wenn the "start on system startup" checkbox is clicked
- (IBAction)preferencesStartupCheckboxAction:(id)sender {
    
    //Case: App is Login Item -> box is checked (see preferencesMenuItemClick)
    //Delete App from List and uncheck the box
    if([self appIsLoginItem]) {
        [self deleteAppFromLoginItem];
        //[_preferencesStartupCheckbox setState:0]; // default behavior, isnt it?
    }
    
    //Case: App is no Login item -> box is unchecked
    //Write App in list and check the box
    else {
        [self addAppAsLoginItem];
        //[_preferencesStartupCheckbox setState:1]; // default behavior, isnt it?
    }
}

//  Override AwakeFromNib
- (void) awakeFromNib {
    
    //  Register the Hotkeys
    EventHotKeyRef gMyHotKeyRef;
    EventHotKeyID gMyHotKeyID;
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    
    InstallApplicationEventHandler(&MyHotKeyHandler,1,&eventType,NULL,NULL);
    
    //  Name and ID of Hotkey
    gMyHotKeyID.signature='htk1';
    gMyHotKeyID.id=1;
    
    // Register the Hotkey
    // Path to file with keyboard codes:
    // /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h
    RegisterEventHotKey(0x15, shiftKey+optionKey, gMyHotKeyID,
                        GetApplicationEventTarget(), 0, &gMyHotKeyRef);
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    self.statusBar.menu = self.menuBarOutlet;
    self.statusBar.highlightMode = YES;
    
    [self testInternetConnection];
    [self.statusBar.menu setDelegate:self]; // Is called when the statusbarmenu is about to open
}

- (void) changeStatusBarIcon:(int *) percentage {
    self.statusBar.image = [NSImage imageNamed: [NSString stringWithFormat: @"icon-progress-%d", (int)percentage]];
}

- (void) resetStatusBarIcon {
    self.statusBar.image = [NSImage imageNamed: @"icon"];
}

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    
    if([[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] count]) {
        // Take the Screenshot
        [AppDelegate takeScreenshot];
    }
    else {
        NSLog(@"Screenshot is forbidden because no User is logged in.");
    }
    return noErr;
}


+ (void) takeScreenshot {
    
    //  Starts Screencapture Process
    NSTask *theProcess;
    theProcess = [[NSTask alloc] init];
    [theProcess setLaunchPath:@"/usr/sbin/screencapture"];
    
    //  Array with Arguments to be given to screencapture
    NSArray *arguments = [NSArray arrayWithObjects:@"-i", @"-c", @"image.jpg", nil];
    
    //  Apply arguments and start application
    [theProcess setArguments:arguments];
    [theProcess launch];
    [theProcess waitUntilExit];
    
    //NSLog(@"%ld", [theProcess terminationReason]);
    
    if ([theProcess terminationStatus] == 0) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *classes = [[NSArray alloc] initWithObjects: [NSImage class], nil];
        NSDictionary *options = [NSDictionary dictionary];
        NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
        
        if ([copiedItems count]) {
            if([[copiedItems objectAtIndex:0] isKindOfClass:[NSImage class]]) {
                NSImage *image = [copiedItems objectAtIndex:0];
                
                NSSize imageSize = [image size]; // Get the Image Size
                NSImageRep *imgrep = [[image representations] objectAtIndex:0];
                NSSize imagePixelSize = NSMakeSize(imgrep.pixelsWide, imgrep.pixelsHigh);
                
                NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
                
                // Downscale Retina Screenshot if Pixelratio > 1.0 and user wants it to
                if((imageSize.width < imagePixelSize.width) && [userPreferences boolForKey: @"downscaleRetinaScreenshots"]) {
                    NSLog(@"Downscaling Retina Screenshot...");// imageSize(%f / %f) and pixelSize(%f / %f)", imageSize.width, imageSize.height, imagePixelSize.width, imagePixelSize.height);
                    
                    image = [functions downscaleToNonRetina: image];
                }
                
                sendPost *post = [[sendPost alloc] init];
                [post uploadImage:image];
            }
        }
        else {
            NSLog(@"Screencaputre aborted.");
        }
    }
}


//  Checks if we have an internet connection or not
- (void)testInternetConnection
{
    internetReachable = [Reachability reachabilityWithHostname:@"51seven.de"];
    
    // Internet is reachable
    internetReachable.reachableBlock = ^(Reachability*reach) {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Connection: ONLINE");
            [_noInternetConnection setHidden: YES];
            self.statusBar.image = [NSImage imageNamed: @"icon"];
            
            //Set takeScreenshotMenuItem to enabled only if the user is logged in
            if([[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] count]) {
                [_takeScreenshotMenuItem setEnabled: YES];
            }
        });
    };
    
    // Internet is not reachable
    internetReachable.unreachableBlock = ^(Reachability*reach) {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Connection: OFFLINE");
            [_noInternetConnection setHidden: NO];
            [_takeScreenshotMenuItem setEnabled: NO];
            self.statusBar.image = [NSImage imageNamed: @"icon-disabled"];
        });
    };
    
    [internetReachable startNotifier];
}


- (IBAction)accountPreferences:(id)sender {    
    for (int i = (int)_preferencesWrapperView.subviews.count-1; i >= 0; i--) {
        [[_preferencesWrapperView.subviews objectAtIndex:i] removeFromSuperview];
    }
    
    [_preferencesWrapperView addSubview:_preferencesAccountView];
    
    // Getting userinformation
    NXOAuth2Account *anAccount = [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"password"] lastObject];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; // Environment Variables
    
    [[NXOAuth2AccountStore sharedStore] setClientID:@"testid"
                                                 secret:@"testsecret"
                                       authorizationURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/api/oauth/token", infoDict[@"serverurl"]]]
                                               tokenURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/api/oauth/token", infoDict[@"serverurl"]]]
                                            redirectURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@", infoDict[@"serverurl"]]]
                                         forAccountType:@"password"];
        
    [[NXOAuth2AccountStore sharedStore] setTrustModeHandlerForAccountType:@"password" block:^NXOAuth2TrustMode(NXOAuth2Connection *connection, NSString *hostname) {
        return NXOAuth2TrustModeAnyCertificate;
    }];
    
    NXOAuth2Request *theRequest = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:[NSString stringWithFormat: @"%@/api/user/info", infoDict[@"serverurl"]]]
                                                                     method:@"POST"
                                                                 parameters:nil];
    
    theRequest.account = anAccount;
    
    NSURLRequest *signedRequest = [theRequest signedURLRequest];
    NSData *returnData = [NSURLConnection sendSynchronousRequest: signedRequest returningResponse: nil error: nil]; // Change to Asynchronus Request
    
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"Response: %@", returnString);

    id json_response = [NSJSONSerialization JSONObjectWithData:returnData options:0 error:nil];
    
    double total = [[[json_response objectForKey: @"storage"] objectForKey: @"total"] doubleValue];

    [_quotaBar setWarningValue: total*0.8];
    [_quotaBar setCriticalValue: total*0.9];
    [_quotaBar setMaxValue: total];
    [_quotaBar setStringValue: [[json_response objectForKey: @"storage"] objectForKey: @"used"]];
    
    [_quotaBarLabel setStringValue: [NSString stringWithFormat: @"%.2f mb used", [[[json_response objectForKey: @"storage"] objectForKey: @"used"] doubleValue]/1024/1024]];

    [_snapsMadeLabel setStringValue: [NSString stringWithFormat: @"You've made %@ snaps.", [json_response objectForKey: @"snaps"]]];
}

- (IBAction)generalPreferences:(id)sender {
    for (int i = (int)_preferencesWrapperView.subviews.count-1; i >= 0; i--) {
        [[_preferencesWrapperView.subviews objectAtIndex:i] removeFromSuperview];
    }
    
    [_preferencesWrapperView addSubview:_preferencesGeneralView];
}

- (IBAction)aboutPreferences:(id)sender {
    for (int i = (int)_preferencesWrapperView.subviews.count-1; i >= 0; i--) {
        [[_preferencesWrapperView.subviews objectAtIndex:i] removeFromSuperview];
    }
    
    [_preferencesWrapperView addSubview:_preferencesAboutView];
}



//
//  Display Notification even if application is not key
//
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

//
//  Triggers a Notification
//  Needs the imageUrl to display it in the notification
//
+ (void)triggerNotification:(NSString *)imageUrl {
    
    //New Notification
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    
    //Properties of the Notification
    notification.title = imageUrl;
    notification.informativeText = @"Link copied to clipboard";
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    //Deliver
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

//
//  Makes the notification clickable
//
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSString *url = notification.title;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

-(void) addAppAsLoginItem {
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
	// Create a reference to the shared file list.
    // We are adding it to the current user only.
    // If we want to add it all users, use
    // kLSSharedFileListGlobalLoginItems instead of kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//Insert an item to the list.
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                     kLSSharedFileListItemLast, NULL, NULL,
                                                                     url, NULL, NULL);
		if (item) {
			CFRelease(item);
        }
	}
    
	CFRelease(loginItems);
}

-(void) deleteAppFromLoginItem{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for(int i = 0 ; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                        objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
	}
}

-(BOOL) appIsLoginItem{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for(int i = 0; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                 objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
                    return YES;
				}
			}
		}
	}
    return NO;
}

@end
