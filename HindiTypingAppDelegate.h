//
//  HindiTypingAppDelegate.h
//  HindiTyping
//
//  Created by Vikram on 2/5/15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HindiTypingAppDelegate : NSObject {
	/// Area to accept keyboard input
	NSTextView *inputArea;
	/// Area to show the instructions.
	NSTextField *instructionArea;
	/// Display for Words Per Minute
	NSTextField *wpm;
	
	/// What the user will type out
	NSString *instruction;
	/// Time at which the typing started.
	NSDate *startTime;
	
	/// The state of the app at any time.
	NSDictionary *appState;

	NSArray *listOfInstructions;
	int currentInstruction;

	BOOL currentlyBad;	
}

@property (retain) IBOutlet NSTextView *inputArea;
@property (retain) IBOutlet NSTextField *instructionArea;
@property (retain) IBOutlet NSTextField *wpm;
@property (retain) NSString *instruction;
@property (retain) NSDate *startTime;
@property (retain) NSArray *listOfInstructions;
@property (retain) NSDictionary *appState;

@property (assign) int currentInstruction;
@property (assign) BOOL currentlyBad;


- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;
- (void) applicationWillTerminate:(NSNotification *)aNotification;
- (void) textDidChange:(NSNotification *)aNotification;

@end
