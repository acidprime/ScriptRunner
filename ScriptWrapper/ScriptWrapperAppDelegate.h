//
//  ScriptWrapperAppDelegate.h
//  ScriptWrapper
//
//  Created by Zack Smith on 12/2/11.
//  Copyright 2011 318 All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface ScriptWrapperAppDelegate : NSObject {
    NSWindow *window;
	NSDictionary *settings;
	
	// Here our NSTask
	NSTask       *task;
	NSFileHandle *fileHandle;
	
	// Reference to this bundle
	NSBundle *thisBundle;
	
	// Our debug variable 
	BOOL debugEnabled;
}
- (void)readInSettings;
- (void)runPrivUtility;
- (void)readPipe:(NSNotification *)notification;
- (void)quit;



@end
