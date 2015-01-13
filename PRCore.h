#import <Cocoa/Cocoa.h>
@class PRBridge;
@class PRConnection;
@class PRDb;
@class PRFolderMonitor;
@class PRGrowl;
@class PRHotKeyController;
@class PRLastfm;
@class PRMainWindowController;
@class PRMediaKeyController;
@class PRPlayer;
@class PRProgressManager;

@interface PRCore : NSObject <NSApplicationDelegate>
@property (readonly) PRBridge *bridge;
@property (readonly) PRConnection *conn;
@property (readonly) PRDb *db;
@property (readonly) PRMainWindowController *win;
@property (readonly) PRPlayer *now;
@property (readonly) NSOperationQueue *opQueue;
@property (readonly) PRFolderMonitor *folderMonitor;
@property (readonly) PRProgressManager *taskManager;
@property (weak, readonly) NSMenu *mainMenu;
@property (readonly) PRLastfm *lastfm;
@property (readonly) PRMediaKeyController *keys;
@property (readonly) PRHotKeyController *hotKeys;
- (void)itunesImport:(id)sender;
- (IBAction)showOpenPanel:(id)sender;
@end
