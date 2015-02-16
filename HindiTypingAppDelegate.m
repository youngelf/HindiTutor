//
//  HindiTypingAppDelegate.m
//  HindiTyping
//
//  Created by Vikram on 2/5/15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "HindiTypingAppDelegate.h"
#include <Carbon/Carbon.h>

@interface HindiTypingAppDelegate ()
/// See the next instruction
- (BOOL) nextInstructionFromArray;

/// Name of the file containing our saved state
- (NSString *) filenameWithStoredState;
@end

// TODO(viki): Store the progress made till now
// TODO(viki): Allow user to resume at a specific spot
// TODO: Menu item to go back to the start or a specific chapter
// TODO: a notion of chapters for each hand and each row.


@implementation HindiTypingAppDelegate
@synthesize inputArea;
@synthesize instructionArea;
@synthesize instruction;
@synthesize wpm;
@synthesize startTime;
@synthesize listOfInstructions;
@synthesize appState;
@synthesize currentInstruction;
@synthesize currentlyBad;

- (id) init {
	self = [super init];
	if (self) {
		[self setCurrentInstruction:-1];
		// Open the main bundle and get the file handle from there
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSString *lessonFile = [mainBundle pathForResource:@"lesson" ofType:@"plist"];
		NSLog (@"Got the location: %@", lessonFile);
		NSArray *pieces = [NSArray arrayWithContentsOfFile:lessonFile];
		[self setListOfInstructions:pieces];
		[self setCurrentlyBad:NO];
	}

	return self;
}

// Name of the file where we will store our state
- (NSString *) filenameWithStoredState {
	return [NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), @"Library/Application Support/HindiTutor", @"saved-state"];
//	return [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"saved-state"];
}

// Returns YES if we are at the end of the input.
- (BOOL) nextInstructionFromArray {
	if ([self currentInstruction] == [[self listOfInstructions] count]) {
		// At the end of the array.
		return YES;
	}
	// Increment the instruction pointer.
	[self setCurrentInstruction:([self currentInstruction]+1)];
	// Use the next instruction from the array.
	[self setInstruction:[[self listOfInstructions] objectAtIndex:[self currentInstruction]]];
	// Clear the input area
	[[self inputArea] setRichText:YES];
	[[self inputArea] setString:@""];
	// Update the text area.
	[[self instructionArea] setStringValue:[self instruction]];
	// And start the timer.
	[self setStartTime:[NSDate date]];
	return NO;
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	NSLog(@"applicationDidFinishLaunching");
	
	// TODO(viki): Read a config file from disk to see if we should resume
	NSString *fileName = [self filenameWithStoredState];
	NSLog(@"Name of file: %@", fileName);
	[self setAppState: [NSMutableDictionary dictionaryWithContentsOfFile:fileName]];
	NSLog(@"Dictionary: %@", [self appState]);
	if ([self appState] == nil) {
		// Write a new file containing the state, not nil
		[self setAppState: [NSMutableDictionary dictionaryWithCapacity:2]];
		[[self appState] setValue:@"initialized" forKey:@"started"];
		BOOL written = [[self appState] writeToFile:fileName atomically:YES ];
		NSLog (@"Wrote (? %d) to a file the dictionary %@", written, [self appState]);
	}

	// Read the instruction the user was doing last.  We subtract one because nextInstructionFromArray will increment this anyway.
	[self setCurrentInstruction:[[[self appState] objectForKey:@"currentInstruction"] intValue] - 1];

	// TODO(viki) Check the return value 
	[self nextInstructionFromArray];

	// Get the current input source name.
	// TODO(viki): 
	TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
	NSString *s = (TISGetInputSourceProperty(source, kTISPropertyInputSourceID));
	NSLog (@"The source name is: %@", s);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save the number of problems solved
	[[self appState] setValue: [NSNumber numberWithInt:[self currentInstruction]] forKey:@"currentInstruction"];
	NSString *fileName = [self filenameWithStoredState];
	BOOL written = [[self appState] writeToFile:fileName atomically:YES ];
	NSLog (@"Wrote (? %d) to a file the dictionary %@", written, [self appState]);	
}


// Some text changed. Check how much is correct and calculate WordsPerMinute.
- (void) textDidChange:(NSNotification *)aNotification{
	NSString *characters = [[self inputArea] string];
	NSLog(@"The string is now %@", characters);
	// Are we done yet? Transition to the next input.
	if ([[self instruction] compare:characters] == NSOrderedSame) {
		NSLog(@"----Next string");
		[self nextInstructionFromArray];
		return;
	}
	if ([[self instruction] hasPrefix:characters]) {
		/// The user is along the right way, show them the words per minute.
		// Count how many words are correctly entered.
		NSRange x = [[self instruction] rangeOfString:characters];
		NSUInteger length = x.length;
		NSTimeInterval timeSpent = -[[self startTime] timeIntervalSinceNow];
		NSLog(@"Length = %d, Time interval = %f", length, timeSpent);
		// Roughly 5 characters make a word.
 		[[self wpm] setStringValue:[NSString stringWithFormat:@"%d", (int) (12.0*length/timeSpent)]];

		// Reset all color to black
//		[[self inputArea] setTextColor:[NSColor blackColor]];
//		[[self instructionArea] setFont:[NSFont boldSystemFontOfSize:32]];
		[[self wpm] setTextColor:[NSColor blackColor]];
		[self setCurrentlyBad:NO];
		// When the entire statement is done, then transition to the next line.
	} else if (![self currentlyBad]) {
		/// Mistake
		[[self wpm] setStringValue:@"BAD"];
		// Highlight the errant character
		// Where is the first mistake?
		NSString *correct = [characters commonPrefixWithString:[self instruction] options:NSLiteralSearch];
		NSLog (@"The correct part is: %@", correct);
//		NSUInteger start = [correct length];
		// And let's find how big the original string is.
//		NSUInteger end = [[self instruction] length] - start;
//		[[self inputArea] setTextColor:[NSColor redColor] range:NSMakeRange(start, start+2)];
//		[[self instructionArea] setFont:[NSFont boldSystemFontOfSize:32] range:NSMakeRange(start, start + 2)];
		[[self wpm] setTextColor:[NSColor redColor]];
		[self setCurrentlyBad:YES];
	}
}

@end
