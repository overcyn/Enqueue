#import <Foundation/Foundation.h>
@class PRCore;


@interface PRMainMenuController : NSObject <NSMenuDelegate> {
    IBOutlet NSMenu *_dockMenu;    
    NSMenu *mainMenu;
    NSMenu *enqueueMenu;
    NSMenu *fileMenu;
    NSMenu *editMenu;
    NSMenu *viewMenu;
    NSMenu *controlsMenu;
    NSMenu *windowMenu;
    NSMenu *helpMenu;
    
    __weak PRCore *core;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
- (NSMenu *)dockMenu;

/* Action */
- (void)showPreferences;

- (void)newPlaylist;
- (void)newSmartPlaylist;
- (void)open;
- (void)itunesImport;
- (void)rescanLibrary;
- (void)rescanFullLibrary;
- (void)duplicateFiles;
- (void)missingFiles;

- (void)find;
- (void)clearNowPlaying;

- (void)viewAsList;
- (void)viewAsAlbumList;
- (void)toggleArtwork;
- (void)toggleMiniPlayer;
- (void)showInfo;
- (void)showCurrentSong;
@end