#import <Cocoa/Cocoa.h>
@class PRDb, PRNowPlayingController, PRMainWindowController, PRFolderMonitor, PRTaskManager, PRGrowl, PRLastfm,
PRMediaKeyController, PRHotKeyController;


@interface PRCore : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *__weak _mainMenu;
    NSConnection *_connection;
    
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
/* Accessors */
@property (readonly) PRDb *db;
@property (readonly) PRMainWindowController *win;
@property (readonly) PRNowPlayingController *now;
@property (readonly) NSOperationQueue *opQueue;
@property (readonly) PRFolderMonitor *folderMonitor;
@property (readonly) PRTaskManager *taskManager;
@property (weak, readonly) NSMenu *mainMenu;
@property (readonly) PRLastfm *lastfm;
@property (readonly) PRMediaKeyController *keys;
@property (readonly) PRHotKeyController *hotKeys;

/* Actions */
- (void)itunesImport:(id)sender;
- (IBAction)showOpenPanel:(id)sender;

/* Error */
- (NSError *)multipleInstancesError;
- (NSError *)couldNotCreateDirectoryError:(NSString *)directory;
@end