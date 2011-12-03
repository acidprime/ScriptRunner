//
//  ScriptController.m
//  ScriptRunner
//
//  Created by Zack Smith on 2/8/10.
//  Copyright 2010 318 All rights reserved.
//
// Need to break off some of this into its own class

#import "ScriptController.h"
#import "Constants.h"

@implementation ScriptController

# pragma mark -
# pragma mark Method Overrides
# pragma mark -

- (id)init
{
    self = [super init];
    if (self)
	{
		// SetUID for Root Run
		setuid(0);
		// Disable Lion State
		if([[NSUserDefaults standardUserDefaults] objectForKey: @"ApplePersistenceIgnoreState"] == nil)
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"ApplePersistenceIgnoreState"];

		// Read out settings in
		[self readInSettings ];

    }
    return self;
}


- (void)awakeFromNib 
{	
	// Activate this application as we are launched by another
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	
	[ self checkHelper];
	// Hide the output box
	[self resetOutputBox];

	[self setupInterface ];
	[self startUpArgumentArray ];
	BOOL runAsRootBool;
	runAsRootBool = [[settings objectForKey:@"scriptSudo"] boolValue];
	if(runAsRootBool){
		[runAsRoot setState:NSOnState];
	}
	else {
		[runAsRoot setState:NSOffState];

	}
	windowTitle = [settings objectForKey:@"windowTitle"];
	[ mainWindow setTitle:windowTitle];
	//[argumentsView setDataSource:self];
	// Setup our NSTextView
	[ logTextView setBackgroundColor:[NSColor blackColor]];
	[ logTextView setInsertionPointColor:[NSColor whiteColor]];
	
	[logTextView setSelectedTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSColor whiteColor], NSBackgroundColorAttributeName,
      [NSColor blackColor], NSForegroundColorAttributeName,
      nil]];


}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

# pragma mark -
# pragma mark Startup & Shutdown Methods
# pragma mark -

- (void)readInSettings 
{ 	
	thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:SettingsFileResourceID ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:path];
	debugEnabled = [[ settings objectForKey:@"debugEnabled"] boolValue];
}

- (void)checkHelper
{
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	// Check to make sure we are running by our helper.
	// usage:  /path/to/app/Contents/Resources/app -helper yes
	BOOL helper = ([standardDefaults objectForKey:@"helper"] != nil);
	if (!helper) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		// Activate Our Application
		[NSApp arrangeInFront:self];
		[NSApp activateIgnoringOtherApps:YES];
		// Display a standard alert
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Ok"];
		[alert setMessageText:@"Invalid Launch Type"];
		[alert setInformativeText:@"This tool is only meant to be launched via its Helper Application"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
		[alert release];
		[pool release];
		// And Quit
		[self quit];
	}
}

-(void)setupInterface
{
	// Enable the button
	[ runScriptButton setEnabled:YES];
	scriptName = [settings objectForKey:@"scriptName"];
	scriptDescription = [settings objectForKey:@"scriptDescription"];
	[scriptNameField setStringValue:scriptName ];
	[scriptDescriptionField setStringValue:scriptDescription ];
	
}

- (void)quit
{
	[NSApp terminate:self];
}
# pragma mark -
# pragma mark NSNotification Methods
# pragma mark -


- (void)windowWillClose:(NSNotification *)aNotification {
	// Quit the app when the window closes
	[self quit];
}
# pragma mark -
#pragma mark NSPanel Methods
# pragma mark -

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSString *filePathChoosen = [panel filename];
	[addArgumentField setStringValue: [NSString stringWithFormat:@"'%@'",filePathChoosen] ];
}

# pragma mark -
# pragma mark NSTableView
# pragma mark -

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return ([arguments count]);
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	return [arguments objectAtIndex:row];
}

# pragma mark -
# pragma mark NSTableView
# pragma mark -




- (void)startUpArgumentArray{
	// create the collection array
	if (arguments) {
		[ arguments release];
	}
	arguments = [[NSMutableArray alloc] init];
	arguments = [settings objectForKey:@"scriptArguments"];
	if(debugEnabled)NSLog(@"arguments: %@",arguments);
}


- (IBAction)configureArguments:(id)sender
{
	// create the collection array
	if (arguments) {
		[ arguments release];
	}
	arguments = [settings objectForKey:@"scriptArguments"];
	[argumentsView reloadData];
	[NSApp beginSheet:configureArgumentsPanel modalForWindow:mainWindow
        modalDelegate:self didEndSelector:NULL contextInfo:nil];
	if(debugEnabled)NSLog(@"User clicked arguments button");
}

- (IBAction)doneConfiguringArguments:(id)sender
{
    [configureArgumentsPanel orderOut:nil];
    [NSApp endSheet:configureArgumentsPanel];
	if(debugEnabled)NSLog(@"Done configuring Arguments");
}


- (void)readLogFile{
	NSString *path = @"/tmp/scriptoutput.log";
	NSError *error;
	NSString *stringFromFileAtPath = [[NSString alloc]
                                      initWithContentsOfFile:path
                                      encoding:NSUTF8StringEncoding
                                      error:&error];
	if (stringFromFileAtPath == nil) {
		// an error occurred
		NSLog(@"Error reading file at %@\n%@",
              path, [error localizedFailureReason]);
	}
}

# pragma mark -
# pragma mark NSTask
# pragma mark -

- (void)runTask{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if(debugEnabled)NSLog(@"DEBUG: Running new NSTask");

	scriptPath = [settings objectForKey:@"scriptPath"];
	
	if(debugEnabled)NSLog(@"DEBUG: scriptPath = %@",scriptPath);

	scriptExtention = [settings objectForKey:@"scriptExtention"];
	
	if(debugEnabled)NSLog(@"DEBUG: scriptExtention = %@",scriptExtention);

	if ([settings objectForKey:@"scriptIsInBundle"]){
		scriptPath = [thisBundle pathForResource:scriptPath ofType:scriptExtention];
		//scriptPath = [thisBundle pathForResource:scriptPath	ofType:@"sh" inDirectory:"@bin"];

		if(debugEnabled)NSLog(@"DEBUG: Script bundle path:%@",scriptPath);
	}
	// Release the task
	if (task) {
		if(debugEnabled) NSLog(@"DEBUG: NSTask found releasing it");
		[task release];
	}	
	if(debugEnabled)NSLog(@"DEBUG: Instantiating NSTask");
	task = [[NSTask alloc] init];
	
	if(debugEnabled) NSLog(@"DEBUG: Creating pipe for NSTask");
	NSPipe *pipe = [NSPipe pipe];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting Standard Output & Error to Pipe");
    [task setStandardOutput: pipe];
    [task setStandardError: [task standardOutput]];
	
	if(debugEnabled) NSLog(@"Setting launchpath to %@",scriptPath);
    [task setLaunchPath: scriptPath];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting arguments to %@",arguments);
	[task setArguments: arguments];
	// Clear Text View
	if(debugEnabled) NSLog(@"DEBUG: Asking main thread to clear textview");
	[self performSelectorOnMainThread:@selector(clearTextView)
						   withObject:nil
						waitUntilDone:false];
	// Set base text
	if(debugEnabled) NSLog(@"DEBUG: Asking main thread add the following text");
	[self performSelectorOnMainThread:@selector(addLogText:)
						   withObject:@"Task in Progress, please wait...\n"
						waitUntilDone:false];
	[self performSelectorOnMainThread:@selector(addLogText:)
						   withObject:@"--------------------------------------------------------------------------------"
						waitUntilDone:false];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting up our file handle");

	fileHandle = [pipe fileHandleForReading];
	[fileHandle readInBackgroundAndNotify];
	
	
	//dup2([fileHandle fileDescriptor], fileno(stdout)) ;
	
	// Add ourself as an observer to read the Pipe
	if(debugEnabled) NSLog(@"DEBUG: Setting our self up as NSFileHandleReadCompletionNotification observer");
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(readPipe:) 
												 name: NSFileHandleReadCompletionNotification 
											   object: fileHandle];
	// Remove our IO buffer
	if(debugEnabled) NSLog(@"DEBUG: Unbuffering IO");
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [task setEnvironment:environment];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting our self up as NSTaskDidTerminateNotification observer");
	// Register for notifications on Task compeletion.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskComplete) 
												 name:NSTaskDidTerminateNotification
											   object:task];
	// Launch the Task
	[task launch];
	[task waitUntilExit];
	
	[pool drain];
	
}

-(void)taskComplete
{
	if(debugEnabled) NSLog(@"DEBUG: NSTask is complete");
	
	// Stop main progress bar
	if(debugEnabled) NSLog(@"DEBUG: Stopping main progress bar");
	[self stopMainProgressIndicator];
	
	// Re-enable Button
	if(debugEnabled) NSLog(@"DEBUG: Re-enabling script button");
	[runScriptButton setEnabled:YES];
	
	// Remove ourself as an observer
	if(debugEnabled) NSLog(@"DEBUG: Removing task observation");
	[[NSNotificationCenter defaultCenter]
	 removeObserver: self
	 name: NSTaskDidTerminateNotification
	 object:task];
	if ([[settings objectForKey:@"quitOnScriptExit"] boolValue]) {
		if(debugEnabled)NSLog(@"Quiting Application at end of run");
		[self quit];
	}
}

# pragma mark -
# pragma mark NSProgressIndicator
# pragma mark -

-(void)startMainProgressIndicator
{
	[mainProgressIndicator setBezeled:YES];
	[mainProgressIndicator setDisplayedWhenStopped:NO];
	[mainProgressIndicator setUsesThreadedAnimation:YES];
	[mainProgressIndicator startAnimation:self];
	
}

-(void)stopMainProgressIndicator
{
	[ mainProgressIndicator stopAnimation:self];
}


-(void)readPipe:(NSNotification *)notification
{
	//if(debugEnabled)NSLog(@"DEBUG: Read Pipe was called");
	NSData *data;
	NSString *text;
	
	data = [[notification userInfo] 
			objectForKey:NSFileHandleNotificationDataItem];
	if (data && [data length]){
		text = [[NSString alloc] initWithData:data 
									 encoding:NSASCIIStringEncoding];
		// Update the text in our text view
		
		[self performSelectorOnMainThread:@selector(addLogText:)
							   withObject:text
							waitUntilDone:false];
		
		NSLog(@"%@",text);
		// Reset the fileHandle
		[text release];
		[[notification object] readInBackgroundAndNotify];
		
	}
	else {
		[[NSNotificationCenter defaultCenter]
		 removeObserver: self
		 name: NSFileHandleReadCompletionNotification
		 object:fileHandle];
	}
	
}


# pragma mark -
# pragma mark NSTextView
# pragma mark -

-(void)addLogText:(NSString *)text
{
	NSRange myRange = NSMakeRange([[logTextView textStorage] length], 0);
	[ [ logTextView textStorage] setForegroundColor:[NSColor whiteColor]];
	NSFont *regular = [NSFont fontWithName:@"Monaco" size:12.0];
	[[logTextView textStorage] setFont:regular];
	[[logTextView textStorage] replaceCharactersInRange:myRange
											 withString:text];
	NSRange scrollRange = NSMakeRange([[logTextView textStorage] length], 0);
	[logTextView scrollRangeToVisible:scrollRange];
}

-(void)clearTextView
{
	NSLog(@"Clear Text View Called");
	[logTextView setString:@""];
}

# pragma mark -

# pragma mark IBAction


-(IBAction)insertFileNameAsArgument:(id)sender
{
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	[openPanel setAllowsMultipleSelection:FALSE];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose"]; // Should be localized
	[openPanel setCanChooseFiles:YES];
	[openPanel setShowsHiddenFiles:YES]; // Will cause warning
	
	[openPanel beginForDirectory:nil
							file:nil
						   types:nil
				modelessDelegate:self
				  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:NULL];
}

- (IBAction)disclosureTrianglePressed:(id)sender {
    NSWindow *window = [sender window];
    NSRect frame = [window frame];
    CGFloat sizeChange = [outputBox frame].size.height;
    switch ([sender state]) {
        case NSOnState:
            // Show the extra box.
			[outputBox setHidden:NO];
            // Make the window bigger.
            frame.size.height += sizeChange;
            // Move the origin.
            frame.origin.y -= sizeChange;
            break;
        case NSOffState:
            // Hide the extra box.
            [outputBox setHidden:YES];
            // Make the window smaller.
            frame.size.height -= sizeChange;
            // Move the origin.
            frame.origin.y += sizeChange;
            break;
        default:
            break;
    }
    [window setFrame:frame display:YES animate:YES];

}

- (void)resetOutputBox{
    NSRect frame = [mainWindow frame];
	CGFloat sizeChange = [outputBox frame].size.height;
	// Hide the extra box.
	[outputBox setHidden:YES];
	// Make the window smaller.
	frame.size.height -= sizeChange;
	// Move the origin.
	frame.origin.y += sizeChange;
	[mainWindow setFrame:frame display:YES animate:NO];
	return;
}

- (IBAction)sendEmail:(id)sender
{
	
	NSString *emailBody	 = [[logTextView textStorage] stringValue];
	
	NSString *emailAddress = [settings objectForKey:@"emailAddress"];
	
	NSString *subject = [NSString stringWithFormat:@"%@ Output",scriptName];

	NSString *body = [NSString stringWithFormat:@"%@\n%@\n%@",
					  scriptName,
					  scriptDescription,
					  emailBody];
	
//	NSLog(@"Subject: %@ ",subject);

//	NSLog(@"Body: %@ ",body);
	
	
	NSString *encodedSubject = [self urlEncode:[subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	body = [body stringByReplacingOccurrencesOfString: @"\n" withString: @"\r"];

	NSString *encodedBody = [self urlEncode:[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//	NSLog(@"Encoded Body: %@ ",encodedBody);
	
	
	NSString *encodedURLString = [NSString stringWithFormat:@"SUBJECT=%@&BODY=%@", encodedSubject, encodedBody];
	
	NSString *sendEmailComplete = [NSString stringWithFormat:@"mailto:%@?%@",emailAddress,encodedURLString];
	NSLog(@"Encoded URL string: %@",sendEmailComplete);

	NSURL *sendEmailURL = [NSURL URLWithString:sendEmailComplete];
	
	NSLog(@"Generated URL: %@ ",sendEmailURL);
	
	if ([[NSWorkspace sharedWorkspace] openURL:sendEmailURL])
	{
		//NSLog(@"Opened %@ successfully.",sendEmailURL);
	}
}


-(IBAction)copyToClipboard:(id)sender
{
	NSString *clipBoard = [logTextView stringValue];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:types owner:self];
    [pb setString: clipBoard forType:NSStringPboardType];
}

# pragma mark -


-(NSString *) urlEncode: (NSString *) url
{
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
							@"@" , @"&" , @"=" , @"+" ,
							@"$" , @"," , @"[" , @"]",
							@"#", @"!", @"'", @"(", 
							@")", @"*", @"\n",@" ",@"\\",@">",@"<",@"_",@"-",@".",@"™",nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
							 @"%3A" , @"%40" , @"%26" ,
							 @"%3D" , @"%2B" , @"%24" ,
							 @"%2C" , @"%5B" , @"%5D", 
							 @"%23", @"%21", @"%27",
							 @"%28", @"%29", @"%2A",@"%0D",@"%20",@"%5C",@"%3E",@"%3C",@"%5F",@"%2D",@"%2E",@"%0D",nil];
	
    int len = [escapeChars count];
	
    NSMutableString *temp = [url mutableCopy];
	
    int i;
    for(i = 0; i < len; i++)
    {
		
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
							  withString:[replaceChars objectAtIndex:i]
								 options:NSLiteralSearch
								   range:NSMakeRange(0, [temp length])];
    }
	
    NSString *out = [NSString stringWithString: temp];
	
    return out;
}


- (IBAction)addArgument:(id)sender {
	[ arguments addObject:[commandLine stringValue]];
    [argumentsView reloadData];
}

- (IBAction)removeSelectedArgument:(id)sender {
    // Remove the selected row from the data set, then reload the table contents.
    [arguments removeObjectAtIndex:[argumentsView selectedRow]];
    [argumentsView reloadData];
}


-(IBAction)runMainScript:(id)sender
{	
	// Start the progress bar
	[self startMainProgressIndicator];
	
	// Disable the main button
	[ runScriptButton setEnabled:NO];
	
	// Check if this should run as current user
	if([runAsRoot state] == NSOnState){
		[NSThread detachNewThreadSelector:@selector(runTask)
								 toTarget:self
							   withObject:nil];
	}
	else{
		[NSThread detachNewThreadSelector:@selector(runTask)
								 toTarget:self
							   withObject:nil];
	}
	
}
@end
