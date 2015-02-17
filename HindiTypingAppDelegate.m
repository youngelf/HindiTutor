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

// The chapter the user is doing.
- (NSArray *) chapter;
// The instruction the user is doing.
- (NSString *) instruction;

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
@synthesize chapterMenu;
@synthesize wpm;
@synthesize startTime;
@synthesize chapterInstructions;
@synthesize currentChapter;
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
		[self setChapterInstructions:pieces];
		// Set the first element as the current chapter.
		[self setCurrentChapter:0];
		[self setCurrentInstruction:0];
		[self setCurrentlyBad:NO];
	}
	return self;
}

- (NSArray *) chapter {
	return [[self chapterInstructions] objectAtIndex:[self currentChapter]];
}

- (NSString *) instruction {
	return [[self chapter] objectAtIndex:[self currentInstruction]];
}

// Name of the file where we will store our state
- (NSString *) filenameWithStoredState {
	return [NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), @"Library/Application Support/HindiTutor", @"saved-state"];
//	return [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"saved-state"];
}

// Returns YES if we are at the end of the input.
- (BOOL) nextInstructionFromArray {
	// Last chapter, and last instruction? Bail.
	if (([self currentChapter] + 1 >= [[self chapterInstructions] count])
		&& ([self currentInstruction] + 1 >= [[self chapter] count])) {
		// At the end of instructions.
		return YES;
	}
	// If we are at the end of the chapter, then go to the next one.
	// TODO(viki): Change the title to show the name of the chapter.
	int nextInstruction = [self currentInstruction] + 1;
	if (nextInstruction >= [[self chapter] count]) {
		// Next chapter.
		NSLog(@"-chapter = %d", [self currentChapter] + 1);
		[self setCurrentChapter:([self currentChapter] + 1)];
		NSLog(@"-Switching to chapter %@", [[self chapter] objectAtIndex:0]);
		// The instruction at position 0 is the name of the chapter.
		nextInstruction = 1;
	}
	NSLog(@"-instruction = %d", nextInstruction);
	[self setCurrentInstruction:nextInstruction];

	// Clear the input area
	[[self inputArea] setRichText:YES];
	[[self inputArea] setString:@""];
	// Update the text area.
	NSLog(@"The instruction is: %@", [self instruction]);
	[[self instructionArea] setStringValue:[self instruction]];
	// And start the timer.
	[self setStartTime:[NSDate date]];
	return NO;
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	NSLog(@"applicationDidFinishLaunching");
	
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

	NSArray *shopping = [NSArray arrayWithObjects:@"milk", @"eggs", @"bread", nil];
	// Now let's iterate over this and create menu items for them.
	for (NSString *item in shopping) {
		NSLog(@"Adding %@", item);
		NSMenuItem *element = [[NSMenuItem alloc] initWithTitle:item action:@selector(switchChapter:) keyEquivalent:@""];
		[element setEnabled:YES];
		[[self chapterMenu] addItem:[element autorelease]];
		NSLog(@"The menu is: %@", element);
	}
	float fontSize = [[[self appState] objectForKey:@"fontSize"] floatValue];
	if (fontSize != 0) {
		[[self inputArea] setFont:[NSFont systemFontOfSize:fontSize]];
	}
	
	// Read the instruction the user was doing last.  We subtract one because nextInstructionFromArray will increment this anyway.
	int chapter = [[[self appState] objectForKey:@"currentChapter"] intValue];
	int instruction = [[[self appState] objectForKey:@"currentInstruction"] intValue];
	NSLog(@"From disk: chapter = %d, instruction = %d", chapter, instruction);
	
	if (chapter + 1 >= [[self chapterInstructions] count]) {
		chapter = 0;
		instruction = 0;
		NSLog(@"Chapter too large: chapter = %d, instruction = %d", chapter, instruction);
	}
	[self setCurrentChapter:chapter];
	if (instruction + 1 >= [[self chapter] count]) {
		instruction = 0;
		NSLog(@"Instruction too large: chapter = %d, instruction = %d", chapter, instruction);
	}
	[self setCurrentInstruction:instruction];

	// TODO(viki) Check the return value 
	[self nextInstructionFromArray];

	// Get the current input source name.
	// TODO(viki): Use this to choose the lesson.
	TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
	NSString *s = (TISGetInputSourceProperty(source, kTISPropertyInputSourceID));
	NSLog (@"The source name is: %@", s);
}

- (void)switchChapter: (id) sender {
	NSLog(@"Switching to chapter %@", sender);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save the number of problems solved
	[[self appState] setValue: [NSNumber numberWithInt:[self currentInstruction]] forKey:@"currentInstruction"];
	[[self appState] setValue: [NSNumber numberWithInt:[self currentChapter]] forKey:@"currentChapter"];
	[[self appState] setValue: [NSNumber numberWithFloat:[[[self inputArea] font] pointSize]] forKey:@"fontSize"];

	NSString *fileName = [self filenameWithStoredState];
	BOOL written = [[self appState] writeToFile:fileName atomically:YES ];
	NSLog (@"Wrote (? %d) to a file the dictionary %@", written, [self appState]);	
}


// Some text changed. Check how much is correct and calculate WordsPerMinute.
- (void) textDidChange:(NSNotification *)aNotification{
	NSString *characters = [[self inputArea] string];
//	NSLog(@"The string is now %@", characters);
	// Are we done yet? Transition to the next input.
	if ([[self instruction] compare:characters] == NSOrderedSame) {
//		NSLog(@"----Next string");
		[self nextInstructionFromArray];
		return;
	}
	if ([[self instruction] hasPrefix:characters]) {
		/// The user is along the right way, show them the words per minute.
		// Count how many words are correctly entered.
		NSRange x = [[self instruction] rangeOfString:characters];
		NSUInteger length = x.length;
		NSTimeInterval timeSpent = -[[self startTime] timeIntervalSinceNow];
//		NSLog(@"Length = %d, Time interval = %f", length, timeSpent);
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
//		NSString *correct = [characters commonPrefixWithString:[self instruction] options:NSLiteralSearch];
//		NSLog (@"The correct part is: %@", correct);
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
