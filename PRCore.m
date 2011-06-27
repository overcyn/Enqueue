#import "PRCore.h"
#import "PRDb.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRImportOperation.h"
#import "PRHistory.h"
#import "PRAlbumArtOperation.h"
#import "PRItunesImportOperation.h"
#import "PRFolderMonitor.h"
#import "PRTaskManager.h"
#import "PRLog.h"
#import "PRWelcomeSheetController.h"
#import "PRUserDefaults.h"
#import "NSFileManager+DirectoryLocations.h"
#import "PRGrowl.h"
#import "PRLastfm.h"


@implementation PRCore

// ========================================
// Initialization
// ========================================

- (id)init 
{
    self = [super init];
    if (self) {
        NSLog(@"date:%@",[NSDate dateWithString:@"tboenuth"]);
        
        connection = [[NSConnection connectionWithReceivePort:[NSPort port] sendPort:[NSPort port]] retain];
        if (![connection registerName:@"enqueue"]) {
            [[PRLog sharedLog] presentFatalError:[self multipleInstancesError]];
        }
        
        NSString *path = [[PRUserDefaults sharedUserDefaults] applicationSupportPath];
        if (![[[[NSFileManager alloc] init] autorelease] findOrCreateDirectoryAtPath:path error:nil]) {
            [[PRLog sharedLog] presentFatalError:[self couldNotCreateDirectoryError:path]];
        }
        
        opQueue = [[NSOperationQueue alloc] init];
        [opQueue setMaxConcurrentOperationCount:1];
        taskManager = [[PRTaskManager alloc] init];
        db = [[PRDb alloc] init];
        now = [[PRNowPlayingController alloc] initWithDb:db]; // requires: db
        folderMonitor = [[PRFolderMonitor alloc] initWithCore:self]; // requires: opQueue, db & taskManager
        win = [[PRMainWindowController alloc] initWithCore:self]; // requires: db, now, taskManager, folderMonitor
        growl  = [[PRGrowl alloc] initWithCore:self];
        lastfm = [[PRLastfm alloc] initWithCore:self];
    }
    return self;
}

- (void)dealloc
{
    [db release];
    [now release];
    [win release];
    [opQueue release];
    [folderMonitor release];
    [taskManager release];
    [super dealloc];
}

- (void)awakeFromNib 
{   
    // Show main window
    [win showWindow:self];
    
    if ([[PRUserDefaults sharedUserDefaults] showWelcomeSheet]) {
        [[PRUserDefaults sharedUserDefaults] setShowWelcomeSheet:FALSE];
        welcomeSheet = [[PRWelcomeSheetController alloc] initWithCore:self];
        [NSApp beginSheet:[welcomeSheet window] 
           modalForWindow:[win window]
            modalDelegate:welcomeSheet
           didEndSelector:NULL
              contextInfo:nil];
    }
}

// ========================================
// Properties
// ========================================

@synthesize db;
@synthesize now;
@synthesize win;
@synthesize opQueue;
@synthesize folderMonitor;
@synthesize taskManager;
@synthesize mainMenu;
@synthesize lastfm;

// ========================================
// Importing
// ========================================

- (IBAction)itunesImport:(id)sender
{
    NSString *folderPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Music"] 
                            stringByAppendingPathComponent:@"iTunes"];;
    NSString *filePath = [folderPath stringByAppendingPathComponent:@"iTunes Music Library.xml"];
    
    if ([[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:filePath]) {
        PRItunesImportOperation *op = 
            [[PRItunesImportOperation alloc] initWithURL:[NSURL fileURLWithPath:filePath] core:self];
        [opQueue addOperation:op];
        [op release];
    } else {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:YES];
        [panel setCanChooseDirectories:NO];
        [panel setCanCreateDirectories:NO];
        [panel setTreatsFilePackagesAsDirectories:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setPrompt:@"Import"];
        [panel setMessage:@"Select the 'iTunes Music Library.xml' file to import."];
        [panel beginSheetForDirectory:folderPath 
                                 file:filePath 
                                types:[NSArray arrayWithObject:@"xml"] 
                       modalForWindow:[win window] 
                        modalDelegate:self
                       didEndSelector:@selector(itunesImportSheetDidEnd:returnCode:context:)
                          contextInfo:nil];
    }
}

- (void)itunesImportSheetDidEnd:(NSOpenPanel*)openPanel 
                     returnCode:(NSInteger)returnCode 
                        context:(void*)context
{
    if (returnCode == NSCancelButton ||
        [[openPanel URLs] count] == 0) {
        return;
    }
    PRItunesImportOperation *op = 
        [[PRItunesImportOperation alloc] initWithURL:[[openPanel URLs] objectAtIndex:0] core:self];
    [opQueue addOperation:op];
    [op release];
}

- (IBAction)getAlbumArt:(id)sender
{
    PRAlbumArtOperation *op = [[PRAlbumArtOperation alloc] initWithDb:db];
    [op main];
    [op release];
}

- (IBAction)showOpenPanel:(id)sender
{    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setTreatsFilePackagesAsDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel beginSheetForDirectory:nil 
                             file:nil 
                   modalForWindow:[win window]
                    modalDelegate:self 
                   didEndSelector:@selector(importSheetDidEnd:returnCode:context:)
                      contextInfo:nil];
}

- (void)importSheetDidEnd:(NSOpenPanel*)openPanel 
               returnCode:(NSInteger)returnCode 
                  context:(void*)context
{
    if (returnCode == NSCancelButton) {
        return;
    }
    
    NSMutableArray *paths = [NSMutableArray array];
    for (NSURL *i in [openPanel URLs]) {
        [paths addObject:[i path]];
    }
    PRImportOperation *op = [[[PRImportOperation alloc] initWithURLs:[openPanel URLs] recursive:TRUE core:self] autorelease];
    [op setPlayWhenDone:TRUE];
    [opQueue addOperation:op];
}

// ========================================
// NSApplication Delegate
// ========================================

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
        [[win window] makeKeyAndOrderFront:nil];
    }
    return TRUE;
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    
    NSArray *URLs = [NSArray arrayWithObject:[NSURL fileURLWithPath:filename]];
    PRImportOperation *op = [[[PRImportOperation alloc] initWithURLs:URLs recursive:TRUE core:self] autorelease];
    [op setPlayWhenDone:TRUE];
    [opQueue addOperation:op];
    return TRUE;
}

- (void)application:(NSApplication *)application openFiles:(NSArray *)filenames
{
    NSMutableArray *URLs = [NSMutableArray array];
    for (NSString *i in filenames) {
        [URLs addObject:[NSURL fileURLWithPath:i]];
    }
    PRImportOperation *op = [[[PRImportOperation alloc] initWithURLs:URLs recursive:TRUE core:self] autorelease];
    [op setPlayWhenDone:TRUE];
    [opQueue addOperation:op]; 
}

// ========================================
// Error
// ========================================

- (NSError *)multipleInstancesError
{
    NSString *description = @"Another instance of Enqueue appears to be running.";
    NSString *recovery = @"Close the other instance and try again.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

- (NSError *)couldNotCreateDirectoryError:(NSString *)directory;
{
    NSString *description = @"Enqueue could not create the following directory and must close.";
    NSString *recovery = directory;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

@end