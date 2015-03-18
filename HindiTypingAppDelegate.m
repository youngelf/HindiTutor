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


static NSString *currentInstructionKey = @"currentInstruction";
static NSString *currentChapterKey = @"currentChapter";
static NSString *fontSizeKey = @"fontSize";
// The normal color of the text area box.  We change it to red when the user makes a mistake.
static NSColor *previousBackgroundColor;


@implementation HindiTypingAppDelegate

@synthesize window;
@synthesize inputArea;
@synthesize instructionArea;
@synthesize chapterMenu;
@synthesize wpm;
@synthesize startTime;
@synthesize chapterInstructions;
@synthesize currentChapter;
@synthesize currentInstruction;
@synthesize currentlyBad;


/// Kill application if our window is shut.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender {
	return YES;
}

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
	int nextInstruction = [self currentInstruction] + 1;
	if (nextInstruction >= [[self chapter] count]) {
		// Next chapter.
		NSLog(@"-chapter = %d", [self currentChapter] + 1);
		[self setCurrentChapter:([self currentChapter] + 1)];
		NSString *chapterName = [[self chapter] objectAtIndex:0];
		NSLog(@"-Switching to chapter %@", chapterName);
		[[self window] setTitle:[NSString stringWithFormat:@"Typing Tutor: %@", chapterName]];
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
	NSMutableDictionary *appState = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
	NSLog(@"Dictionary: %@", appState);
	if (appState == nil) {
		// Write a new file containing the state, not nil
		appState = [NSMutableDictionary dictionaryWithCapacity:2];
		[appState setValue:@"initialized" forKey:@"started"];
		BOOL written = [appState writeToFile:fileName atomically:YES ];
		NSLog (@"Wrote (status = %d) to a file the dictionary %@", written, appState);
	}

	// Create names of chapters from the list.
	for (int i=0, size = [[self chapterInstructions] count]; i<size; ++i) {
		NSArray *chapter = [[self chapterInstructions] objectAtIndex:i];
		NSString *chapterName = [chapter objectAtIndex:0];
		NSMenuItem *element = [[NSMenuItem alloc] initWithTitle:chapterName action:@selector(switchChapter:) keyEquivalent:@""];
		[element setTag:i];
		[element setEnabled:YES];
		[[self chapterMenu] addItem:[element autorelease]];
		NSLog(@"The menu is: %@", element);
	}

	float fontSize = [[appState objectForKey:fontSizeKey] floatValue];
	if (fontSize != 0) {
		[[self inputArea] setFont:[NSFont systemFontOfSize:fontSize]];
	}
	
	// Read the instruction the user was doing last.  We subtract one because nextInstructionFromArray will increment this anyway.
	int chapter = [[appState objectForKey:currentChapterKey] intValue];
	int instruction = [[appState objectForKey:currentInstructionKey] intValue];
	NSLog(@"From disk: chapter = %d, instruction = %d", chapter, instruction);
	
	if (chapter + 1 >= [[self chapterInstructions] count]) {
		chapter = 0;
		instruction = 1;
		NSLog(@"Chapter too large: chapter = %d, instruction = %d", chapter, instruction);
	}
	[self setCurrentChapter:chapter];
	NSString *chapterName = [[self chapter] objectAtIndex:0];
	[[self window] setTitle:[NSString stringWithFormat:@"Typing Tutor: %@", chapterName]];
	if (instruction + 1 >= [[self chapter] count]) {
		instruction = 1;
		NSLog(@"Instruction too large: chapter = %d, instruction = %d", chapter, instruction);
	}
	// nextInstructionFromArray will increment this, so reduce the instruction number in advance.
	[self setCurrentInstruction:instruction - 1];

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
	NSMenuItem *item = (NSMenuItem *)sender;
	int chapter = [item tag];
	// TODO: highlight it.
	[self setCurrentChapter:chapter];
	[self setCurrentInstruction:0];
	// Display chapter name in the title.
	NSString *chapterName = [[self chapter] objectAtIndex:0];
	NSLog(@"switchChapter: Switching to chapter %@", chapterName);
	[[self window] setTitle:[NSString stringWithFormat:@"Typing Tutor: %@", chapterName]];
	[self setCurrentlyBad:NO];
	[self nextInstructionFromArray];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save the number of problems solved
	NSMutableDictionary *appState = [NSMutableDictionary dictionaryWithCapacity:3];
	[appState setValue: [NSNumber numberWithInt:[self currentInstruction]] forKey:currentInstructionKey];
	[appState setValue: [NSNumber numberWithInt:[self currentChapter]] forKey:currentChapterKey];
	[appState setValue: [NSNumber numberWithFloat:[[[self inputArea] font] pointSize]] forKey:fontSizeKey];

	NSString *fileName = [self filenameWithStoredState];
	BOOL written = [appState writeToFile:fileName atomically:YES ];
	NSLog(@"Wrote state to disk (status=%d), state = %@", written, appState);
}

- (void) setCurrentlyBad: (BOOL) bad {
	// If nothing changed, ignore
	if ([self currentlyBad] == bad) {
		return;
	}
	if (bad) {
		// User made a mistake
		[[self wpm] setStringValue:@"BAD"];
		[[self wpm] setTextColor:[NSColor redColor]];
		previousBackgroundColor = [[self instructionArea] backgroundColor];
		[[self instructionArea] setBackgroundColor:[NSColor redColor]];
	} else {
		// User corrected the previous mistake
		[[self instructionArea] setBackgroundColor:previousBackgroundColor];
		[[self wpm] setTextColor:[NSColor blackColor]];
		[[self wpm] setStringValue:@""];
	}
	currentlyBad = bad;
}


// Some text changed. Check how much is correct and calculate WordsPerMinute.
- (void) textDidChange:(NSNotification *)aNotification {
	NSString *characters = [[self inputArea] string];
	// Are we done yet? Transition to the next input.
	if ([[self instruction] compare:characters] == NSOrderedSame) {
		[self nextInstructionFromArray];
		return;
	}
	if ([[self instruction] hasPrefix:characters]) {
		/// The user is along the right way, show them the words per minute.
		// Count how many words are correctly entered.
		NSRange x = [[self instruction] rangeOfString:characters];
		NSUInteger length = x.length;
		NSTimeInterval timeSpent = -[[self startTime] timeIntervalSinceNow];
		// Roughly 5 characters make a word.
 		[[self wpm] setStringValue:[NSString stringWithFormat:@"%d", (int) (12.0*length/timeSpent)]];

		[self setCurrentlyBad:NO];
	} else {
		[self setCurrentlyBad:YES];
	}
}


// Core data
/**
 Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "Untitledkjh" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    NSString *folder = [basePath stringByAppendingPathComponent:@"HindiTyping"];
	NSLog (@"Returning %@ as the folder", folder);
	return folder;
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"HindiTypingState.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
	
    return persistentStoreCoordinator;
}


/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.
				
                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
				
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 
				
                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void) dealloc {
	
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}



@end
