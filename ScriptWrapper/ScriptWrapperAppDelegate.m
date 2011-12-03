//
//  ScriptWrapperAppDelegate.m
//  ScriptWrapper
//
//  Created by Zack Smith on 12/2/11.
//  Copyright 2011 318 All rights reserved.
//

#import "ScriptWrapperAppDelegate.h"
#import "Constants.h"

@implementation ScriptWrapperAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[NSThread detachNewThreadSelector:@selector(runPrivUtility)
							 toTarget:self
						   withObject:nil];
}

-(id)init
{
    [ super init];
	thisBundle = [NSBundle bundleForClass:[self class]];
	[ self readInSettings];
	// And Return
	if (!self) return nil;
    return self;
}

-(void)quit
{
	[NSApp terminate:self];
}

-(void)runPrivUtility
{	
	if (task) {
		NSLog(@"Found existing task...releasing");
		[task release];
	}
	task = [[NSTask alloc] init];
	NSLog(@"Creating pipe for task");
	NSPipe *pipe = [NSPipe pipe];
	
	NSLog(@"Setting Standard Output & Error to Pipe");
    [task setStandardOutput: pipe];
    [task setStandardError: [task standardOutput]];
	// Set the Helper application as the Main Task path
	NSString *helper = [thisBundle pathForResource:[ settings objectForKey:@"myScriptHelper"]
											ofType:nil];
	
	NSLog(@"Found helper path: %@",helper);
	[task setLaunchPath:helper];
	
	// Set the child app as our argument
	NSString *app = [thisBundle pathForResource:[settings objectForKey:@"myScriptRunner"]
										 ofType:[settings objectForKey:@"myScriptExtension"]];
	
	
	app = [app stringByAppendingString:[settings objectForKey:@"myScriptExec"]];
	
	
	NSLog(@"Found app path: %@",app);
	
	[task setArguments:[NSArray arrayWithObjects:app,@"-helper",@"yes",
						nil]];
	// Add ourself as an observer to read the Pipe
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(readPipe:) 
												 name: NSFileHandleReadCompletionNotification 
											   object: fileHandle];
	
	// Remove our IO buffer
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [task setEnvironment:environment];
	
	//Set to help with Xcode console log issues
	//[task setStandardInput:[NSPipe pipe]];
	
	fileHandle = [pipe fileHandleForReading];
	[fileHandle readInBackgroundAndNotify];
	
	// Register for notifications on Task compeletion.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(quit) 
												 name:NSTaskDidTerminateNotification
											   object:task];
	// Launch the Task
	[task launch];
	// Called in a background thread so no blocking
	[task waitUntilExit];
}

-(void)readPipe:(NSNotification *)notification
{
	NSLog(@"Read Pipe was called");
	NSData *data;
	NSString *text;
	
	data = [[notification userInfo] 
			objectForKey:NSFileHandleNotificationDataItem];
	if (data && [data length]){
		text = [[NSString alloc] initWithData:data 
									 encoding:NSASCIIStringEncoding];
		
		
		NSLog(@"%@",text);
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

- (void)readInSettings 
{ 	
	thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:SettingsFileResourceID ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:path];
	debugEnabled = [[ settings objectForKey:@"debugEnabled"] boolValue];
}

@end
