//
//  ScriptController.h
//  ScriptRunner
//
//  Created by Zack Smith on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArgumentArrayController.h"
#import "Constants.h"

@interface ScriptController : NSObject {
	ScriptController *ScriptController;
	ArgumentArrayController *myArgumentArrayController;
	
	// Our Outlets
	//NSButtons
	IBOutlet NSButton *runScriptButton;
	IBOutlet NSWindow *mainWindow ;
	IBOutlet NSPanel *configureArgumentsPanel;
	IBOutlet NSBox *outputBox ;
	
	// NSTextField
	IBOutlet NSTextField *scriptNameField;
	IBOutlet NSTextField *scriptDescriptionField;
	IBOutlet NSTextField *commandLine ;
	IBOutlet NSTextField *addArgumentField;
	
	// NSTableViews
	IBOutlet NSTableView *argumentsView;
	IBOutlet NSButton *runAsRoot;
	
	//NSProgressIndicator
	IBOutlet NSProgressIndicator *mainProgressIndicator;
	
	//NSTextview
	IBOutlet NSTextView  *		logTextView;
	
	NSDictionary *settings;
	
	NSMutableArray *arguments;

	//NSStrings
	NSString *scriptName;
	NSString *scriptDescription;
	NSString *scriptPath;
	NSString *scriptExtention;
	NSString *windowTitle;
	
	NSBundle *thisBundle;
	
	// NSTask
	NSTask       *task;
	NSFileHandle *fileHandle;

	
	BOOL debugEnabled;

}

// IBActions
- (IBAction)runMainScript:(id)sender;
- (IBAction)disclosureTrianglePressed:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)configureArguments:(id)sender;
- (IBAction)doneConfiguringArguments:(id)sender;
- (IBAction)removeSelectedArgument:(id)sender;
- (IBAction)addArgument:(id)sender;
- (IBAction)sendEmail:(id)sender;
- (IBAction)insertFileNameAsArgument:(id)sender;

-(NSString *) urlEncode: (NSString *) url;

- (void)resetOutputBox;
- (void)runTask;
- (void)taskComplete;
- (void)readLogFile;

- (void)readInSettings;
- (void)setupInterface;
- (void)startUpArgumentArray;

// NSNotification

- (void)readPipe:(NSNotification *)notification;
- (void)addLogText:(NSString *)text;
- (void)clearTextView;

//NSProgressIndicator
- (void)startMainProgressIndicator;
- (void)stopMainProgressIndicator;
- (void)checkHelper;
- (void)quit;

@end
