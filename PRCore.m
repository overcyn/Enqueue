#import "PRCore.h"
#import "NSFileManager+DirectoryLocations.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PREnableLogger.h"
#import "PRFolderMonitor.h"
#import "PRFullRescanOperation.h"
#import "PRGrowl.h"
#import "PRHotKeyController.h"
#import "PRImportOperation.h"
#import "PRItunesImportOperation.h"
#import "PRLastfm.h"
#import "PRMainMenuController.h"
#import "PRMainWindowController.h"
#import "PRMediaKeyController.h"
#import "PRNowPlayingController.h"
#import "PRTaskManager.h"
#import "PRTrialSheetController.h"
#import "PRVacuumOperation.h"
#import "PRWelcomeSheetController.h"
#import "PRConnection.h"
#import "PRActionCenter.h"


@implementation PRCore {
    IBOutlet NSMenu *__weak _mainMenu;
    NSConnection *_connection;
    
    PRConnection *_conn1;
    PRConnection *_conn2;
    PRDb *_db;
    PRNowPlayingController *_now;
    PRMainWindowController *_win;
    NSOperationQueue *_opQueue;
    PRFolderMonitor *_folderMonitor;
    PRTaskManager *_taskManager;
    PRGrowl *_growl;
    PRLastfm *_lastfm;
    PRMediaKeyController *_keys;
    PRHotKeyController *_hotKeys;
}

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    
    // Prevent multiple instances of application
    _connection = [NSConnection connectionWithReceivePort:[NSPort port] sendPort:[NSPort port]];
    if (![_connection registerName:@"enqueue"]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Another instance of Enqueue appears to be running.", 
            NSLocalizedRecoverySuggestionErrorKey:@"Close the other instance and try again."};
        [[PRLog sharedLog] presentFatalError:[NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo]];
    }
    
    NSString *path = [[PRDefaults sharedDefaults] applicationSupportPath];
    if (![[[NSFileManager alloc] init] findOrCreateDirectoryAtPath:path error:nil]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Enqueue could not create the following directory and must close.", 
            NSLocalizedRecoverySuggestionErrorKey:path};
        [[PRLog sharedLog] presentFatalError:[NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo]];
    }
    
    [[PRActionCenter defaultCenter] setCore:self];
    _opQueue = [[NSOperationQueue alloc] init];
    [_opQueue setMaxConcurrentOperationCount:1];
    [_opQueue setSuspended:YES];
    _taskManager = [[PRTaskManager alloc] init];
    _db = [[PRDb alloc] initWithCore:self];
    _conn1 = [[PRConnection alloc] initWithPath:[[PRDefaults sharedDefaults] libraryPath] type:PRConnectionTypeReadWrite];
    _conn2 = [[PRConnection alloc] initWithPath:[[PRDefaults sharedDefaults] libraryPath] type:PRConnectionTypeReadOnly];
    _now = [[PRNowPlayingController alloc] initWithDb:_db]; // requires: db
    _folderMonitor = [[PRFolderMonitor alloc] initWithCore:self]; // requires: opQueue, db & taskManager
    _win = [[PRMainWindowController alloc] initWithCore:self]; // requires: db, now, taskManager, folderMonitor
    _growl  = [[PRGrowl alloc] initWithCore:self];
    _lastfm = [[PRLastfm alloc] initWithCore:self];
    _keys = [[PRMediaKeyController alloc] initWithCore:self];
    _hotKeys = [[PRHotKeyController alloc] initWithCore:self];
    return self;
}

- (void)dealloc {
    [_connection invalidate];
}

- (void)awakeFromNib {
    [_win showWindow:nil];
    [_opQueue setSuspended:NO];
    
//    PRTrialSheetController *trialSheet = [[PRTrialSheetController alloc] initWithCore:self]; 
//    [trialSheet beginSheetModalForWindow:[_win window] completionHandler:^{}];
    
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsShowWelcomeSheet]) {
        [[PRDefaults sharedDefaults] setBool:NO forKey:PRDefaultsShowWelcomeSheet];
        PRWelcomeSheetController *welcomeSheet = [[PRWelcomeSheetController alloc] initWithCore:self];
        [welcomeSheet beginSheetModalForWindow:[_win window] completionHandler:^{}];
    }
}

#pragma mark - Accessors

@synthesize db = _db;
@synthesize now = _now;
@synthesize win = _win;
@synthesize opQueue = _opQueue;
@synthesize folderMonitor = _folderMonitor;
@synthesize taskManager = _taskManager;
@synthesize mainMenu = _mainMenu;
@synthesize lastfm = _lastfm;
@synthesize keys = _keys;
@synthesize hotKeys = _hotKeys;
@synthesize conn1 = _conn1;
@synthesize conn2 = _conn2;

#pragma mark - Action

- (void)itunesImport:(id)sender {
    NSString *folderPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Music"] stringByAppendingPathComponent:@"iTunes"];;
    NSString *filePath = [folderPath stringByAppendingPathComponent:@"iTunes Music Library.xml"];
    if ([[[NSFileManager alloc] init] fileExistsAtPath:filePath]) {
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
        [panel setAllowedFileTypes:@[@"xml"]];
        [panel beginSheetModalForWindow:[_win window] completionHandler:^(NSInteger result) {
            if (result == NSCancelButton || [[panel URLs] count] == 0) {return;}
            PRItunesImportOperation *op = [PRItunesImportOperation operationWithURL:[[panel URLs] objectAtIndex:0] core:self];
            [_opQueue addOperation:op];
        }];
    }
}

- (IBAction)showOpenPanel:(id)sender {
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
        PRImportOperation *op = [[PRImportOperation alloc] initWithURLs:[panel URLs] core:self];
        [_opQueue addOperation:op];
    };
    [panel beginSheetModalForWindow:[_win window] completionHandler:handler];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // no-op
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [[_win window] makeKeyAndOrderFront:nil];
    }
    return YES;
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename {
    NSLog(@"openingFiles:%@",filename);
    NSArray *URLs = @[[NSURL fileURLWithPath:filename]];
    PRImportOperation *op = [PRImportOperation operationWithURLs:URLs core:self];
    [_opQueue addOperation:op];
    return YES;
}

- (void)application:(NSApplication *)application openFiles:(NSArray *)filenames {
    NSLog(@"openingFiles:%@",filenames);
    NSMutableArray *URLs = [NSMutableArray array];
    for (NSString *i in filenames) {
        [URLs addObject:[NSURL fileURLWithPath:i]];
    }
    PRImportOperation *op = [PRImportOperation operationWithURLs:URLs core:self];
    [_opQueue addOperation:op]; 
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    return [[_win mainMenuController] dockMenu];
}

@end
