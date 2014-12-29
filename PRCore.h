#import <Cocoa/Cocoa.h>

@class PRDb; 
@class PRNowPlayingController; 
@class PRMainWindowController; 
@class PRFolderMonitor; 
@class PRProgressManager; 
@class PRGrowl; 
@class PRLastfm; 
@class PRMediaKeyController; 
@class PRHotKeyController;
@class PRConnection;


@interface PRCore : NSObject <NSApplicationDelegate>
/* Accessors */
@property (readonly) PRConnection *conn;
@property (readonly) PRDb *db;
@property (readonly) PRMainWindowController *win;
@property (readonly) PRNowPlayingController *now;
@property (readonly) NSOperationQueue *opQueue;
@property (readonly) PRFolderMonitor *folderMonitor;
@property (readonly) PRProgressManager *taskManager;
@property (weak, readonly) NSMenu *mainMenu;
@property (readonly) PRLastfm *lastfm;
@property (readonly) PRMediaKeyController *keys;
@property (readonly) PRHotKeyController *hotKeys;

/* Actions */
- (void)itunesImport:(id)sender;
- (IBAction)showOpenPanel:(id)sender;
@end
