#import "PRCore.h"
#import "PRDb.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRImportOperation.h"
#import "PRItunesImportOperation.h"
#import "PRFolderMonitor.h"
#import "PRTaskManager.h"
#import "PRWelcomeSheetController.h"
#import "PRUserDefaults.h"
#import "NSFileManager+DirectoryLocations.h"
#import "PRGrowl.h"
#import "PRLastfm.h"
#import "PRVacuumOperation.h"
#include "PREnableLogger.h"
#import "PRMainMenuController.h"
#import "PRKeyboardShortcuts.h"
#import "PRFullRescanOperation.h"

@implementation PRCore

// ========================================
// Initialization
// ========================================

- (id)init
{
    if (!(self = [super init])) {return nil;}
    // Register a connection. Prevents multiple instances of application
    _connection = [[NSConnection connectionWithReceivePort:[NSPort port] sendPort:[NSPort port]] retain];
    if (![_connection registerName:@"enqueue"]) {
        [[PRLog sharedLog] presentFatalError:[self multipleInstancesError]];
    }
    
    NSString *path = [[PRUserDefaults userDefaults] applicationSupportPath];
    if (![[[[NSFileManager alloc] init] autorelease] findOrCreateDirectoryAtPath:path error:nil]) {
        [[PRLog sharedLog] presentFatalError:[self couldNotCreateDirectoryError:path]];
    }
    
//    [PREnableLogger enableLogger];
    
    _opQueue = [[NSOperationQueue alloc] init];
    [_opQueue setMaxConcurrentOperationCount:1];
    [_opQueue setSuspended:TRUE];
    _taskManager = [[PRTaskManager alloc] init];
    _db = [[PRDb alloc] initWithCore:self];
    _now = [[PRNowPlayingController alloc] initWithDb:_db]; // requires: db
    _folderMonitor = [[PRFolderMonitor alloc] initWithCore:self]; // requires: opQueue, db & taskManager
    _win = [[PRMainWindowController alloc] initWithCore:self]; // requires: db, now, taskManager, folderMonitor
    _growl  = [[PRGrowl alloc] initWithCore:self];
    _lastfm = [[PRLastfm alloc] initWithCore:self];
    _keys = [[PRKeyboardShortcuts alloc] initWithCore:self];
    return self;
}

- (void)dealloc
{
    [_db release];
    [_now release];
    [_win release];
    [_opQueue release];
    [_folderMonitor release];
    [_taskManager release];
    [_growl release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [_win showWindow:nil];
    if ([[PRUserDefaults userDefaults] showWelcomeSheet]) {
        [[PRUserDefaults userDefaults] setShowWelcomeSheet:FALSE];
        _welcomeSheet = [[PRWelcomeSheetController alloc] initWithCore:self];
        [NSApp beginSheet:[_welcomeSheet window] 
           modalForWindow:[_win window]
            modalDelegate:_welcomeSheet
           didEndSelector:nil
              contextInfo:nil];
    }
//    [_opQueue addOperation:[[[PRVacuumOperation alloc] initWithCore:self] autorelease]];
    [_opQueue setSuspended:FALSE];
}

// ========================================
// Properties
// ========================================

@synthesize db = _db;
@synthesize now = _now;
@synthesize win = _win;
@synthesize opQueue = _opQueue;
@synthesize folderMonitor = _folderMonitor;
@synthesize taskManager = _taskManager;
@synthesize mainMenu = _mainMenu;
@synthesize lastfm = _lastfm;
@synthesize keys = _keys;

// ========================================
// Importing
// ========================================

- (IBAction)itunesImport:(id)sender
{
    NSString *folderPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Music"] stringByAppendingPathComponent:@"iTunes"];;
    NSString *filePath = [folderPath stringByAppendingPathComponent:@"iTunes Music Library.xml"];
    if ([[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:filePath]) {
        PRItunesImportOperation *op = [PRItunesImportOperation operationWithURL:[NSURL fileURLWithPath:filePath] core:self];
        [_opQueue addOperation:op];
    } else {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:YES];
        [panel setCanChooseDirectories:NO];
        [panel setCanCreateDirectories:NO];
        [panel setTreatsFilePackagesAsDirectories:NO];
        [panel setAllowsMultipleSelection:NO];
        [panel setPrompt:@"Import"];
        [panel setMessage:@"Select the 'iTunes Music Library.xml' file to import."];
        [panel setDirectoryURL:[NSURL fileURLWithPath:filePath]];
        [panel setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
        void (^handler)(NSInteger result) = ^(NSInteger result) {
            if (result == NSCancelButton || [[panel URLs] count] == 0) {return;}
            PRItunesImportOperation *op = [PRItunesImportOperation operationWithURL:[[panel URLs] objectAtIndex:0] core:self];
            [_opQueue addOperation:op];
        };
        [panel beginSheetModalForWindow:[_win window] completionHandler:handler];
    }
}

- (IBAction)showOpenPanel:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setTreatsFilePackagesAsDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    void (^handler)(NSInteger result) = ^(NSInteger result) {
        if (result == NSCancelButton) {return;}
        NSMutableArray *paths = [NSMutableArray array];
        for (NSURL *i in [panel URLs]) {
            [paths addObject:[i path]];
        }
        PRImportOperation *op = [[[PRImportOperation alloc] initWithURLs:[panel URLs] core:self] autorelease];
        [_opQueue addOperation:op];
    };
    [panel beginSheetModalForWindow:[_win window] completionHandler:handler];
}

// ========================================
// NSApplication Delegate
// ========================================

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
        [[_win window] makeKeyAndOrderFront:nil];
    }
    return TRUE;
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    NSArray *URLs = [NSArray arrayWithObject:[NSURL fileURLWithPath:filename]];
    PRImportOperation *op = [PRImportOperation operationWithURLs:URLs core:self];
    [_opQueue addOperation:op];
    return TRUE;
}

- (void)application:(NSApplication *)application openFiles:(NSArray *)filenames
{
    NSMutableArray *URLs = [NSMutableArray array];
    for (NSString *i in filenames) {
        [URLs addObject:[NSURL fileURLWithPath:i]];
    }
    PRImportOperation *op = [PRImportOperation operationWithURLs:URLs core:self];
    [_opQueue addOperation:op]; 
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    NSMenu *menu = [[_win mainMenuController] dockMenu];
    if (menu) {
        return menu;
    }
    return nil;
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