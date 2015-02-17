//
//  HindiTypingAppDelegate.h
//  HindiTyping
//
//  Created by Vikram on 2/5/15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HindiTypingAppDelegate : NSObject {
	// The main window
	NSWindow *window;
	/// Area to accept keyboard input
	NSTextView *inputArea;
	/// Area to show the instructions.
	NSTextField *instructionArea;
	/// Display for Words Per Minute
	NSTextField *wpm;
	// The chapter menu
	NSMenu *chapterMenu;

	/// Time at which the typing started.
	NSDate *startTime;
	
	// Array of arrays.  First array contains chapter.  Inner arrays contain instructions.
	NSArray *chapterInstructions;
	// The current chapter, an index into chapterInstructions.
	int currentChapter;
	// The current instruction, an index into [chapterInstructions objectAtIndex:currentChapter]
	int currentInstruction;

	BOOL currentlyBad;	
}

@property (retain) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSTextView *inputArea;
@property (retain) IBOutlet NSTextField *instructionArea;
@property (retain) IBOutlet NSTextField *wpm;
@property (retain) IBOutlet NSMenu *chapterMenu;
@property (retain) NSDate *startTime;
@property (retain) NSArray *chapterInstructions;

@property (assign) int currentInstruction;
@property (assign) int currentChapter;
@property (assign) BOOL currentlyBad;


- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;
- (void) applicationWillTerminate:(NSNotification *)aNotification;
- (void) textDidChange:(NSNotification *)aNotification;
- (void) switchChapter: (id) sender;

@end
