#import <Cocoa/Cocoa.h>
@class PRCore;

@interface PRMainMenuController : NSObject <NSMenuDelegate>
- (id)initWithCore:(PRCore *)core;
- (NSMenu *)dockMenu;

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