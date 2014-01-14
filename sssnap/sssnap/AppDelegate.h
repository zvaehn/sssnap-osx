//
//  AppDelegate.h
//  sssnap
//
//  Created by Christian Poplawski on 13.01.14.
//  Copyright (c) 2014 AwesomePeople. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;

- (IBAction)takeScreenshot:(id)sender;
- (IBAction)signIn:(id)sender;


@property (weak) IBOutlet NSTextField *usernameLabel;
@property (weak) IBOutlet NSTextField *passwordLabel;

@property (weak) IBOutlet NSMenuItem *signIn;

@property (weak) IBOutlet NSTextField *usernameInput;
@property (weak) IBOutlet NSSecureTextField *passwordInput;



@property (weak) IBOutlet NSMenu *menuBarOutlet;
@property (strong, nonatomic) NSStatusItem *statusBar;

@end
