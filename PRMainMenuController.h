#import <Foundation/Foundation.h>

@class PRCore;


@interface PRMainMenuController : NSObject <NSMenuDelegate>
{
    PRCore *core;
    
    NSMenu *mainMenu;
    NSMenu *enqueueMenu;
    NSMenu *libraryMenu;
    NSMenu *editMenu;
    NSMenu *viewMenu;
    NSMenu *controlsMenu;
    NSMenu *windowMenu;
    NSMenu *helpMenu;

}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Action

- (void)showPreferences;
- (void)newPlaylist;
- (void)viewAsList;
- (void)viewAsAlbumList;
- (void)browserOnTop;
- (void)browserOnLeft;
- (void)browserHidden;
- (void)browserToggleGenre;
- (void)browserToggleComposer;
- (void)browserToggleArtist;
- (void)browserToggleAlbum;
- (void)showCurrentSong;
- (void)showInfo;
- (void)toggleArtwork;

@end