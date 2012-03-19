#import <Cocoa/Cocoa.h>
@class PRDb, PRNowPlayingController, PRMainWindowController, PRFolderMonitor, PRTaskManager, PRGrowl, PRLastfm, PRKeyboardShortcuts;


@interface PRCore : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *_mainMenu;
    NSConnection *_connection;
    
	PRDb *_db;
	PRNowPlayingController *_now;
	PRMainWindowController *_win;
	NSOperationQueue *_opQueue;
    PRFolderMonitor *_folderMonitor;
    PRTaskManager *_taskManager;
    PRGrowl *_growl;
    PRLastfm *_lastfm;
    PRKeyboardShortcuts *_keys;
}
/* Accessors */
@property (readonly) PRDb *db;
@property (readonly) PRMainWindowController *win;
@property (readonly) PRNowPlayingController *now;
@property (readonly) NSOperationQueue *opQueue;
@property (readonly) PRFolderMonitor *folderMonitor;
@property (readonly) PRTaskManager *taskManager;
@property (readonly) NSMenu *mainMenu;
@property (readonly) PRLastfm *lastfm;
@property (readonly) PRKeyboardShortcuts *keys;

/* Actions */
- (void)itunesImport:(id)sender;
- (IBAction)showOpenPanel:(id)sender;

/* Error */
- (NSError *)multipleInstancesError;
- (NSError *)couldNotCreateDirectoryError:(NSString *)directory;
@end