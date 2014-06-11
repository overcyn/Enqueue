#import "PRGrowl.h"
#import "Growl/Growl.h"
#import "PRNowPlayingController.h"
#import "PRDefaults.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRTimeFormatter.h"
#import "PRAlbumArtController.h"
#import "PRMoviePlayer.h"


@interface PRGrowl ()
- (void)currentFileDidChange:(NSNotification *)notification;
@end


@implementation PRGrowl

- (id)initWithCore:(PRCore *)core_ {
    if (!(self = [super init])) {return nil;}
    _core = core_;
    _db = [_core db];
    [GrowlApplicationBridge setGrowlDelegate:self];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(currentFileDidChange:)];
//    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(playingChanged:)];
    return self;
}

- (void)dealloc {
    [GrowlApplicationBridge setGrowlDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playingChanged:(NSNotification *)notification {
    PRItem *item = [[_core now] currentItem];
    if (![[PRDefaults sharedDefaults] boolForKey:PRDefaultsPostGrowl] || !item || ![[[_core now] mov] isPlaying]) {
        return;
    }
    NSString *title = [[_db library] valueForItem:item attr:PRItemAttrTitle];
    NSString *artist = [[_db library] artistValueForItem:item];
    NSString *album = [[_db library] valueForItem:item attr:PRItemAttrAlbum];
    NSNumber *time = [[_db library] valueForItem:item attr:PRItemAttrTime];
    NSString *formattedTime = [[[PRTimeFormatter alloc] init] stringForObjectValue:time];
    NSData *artwork = [[[[_core db] albumArtController] artworkForItem:item] TIFFRepresentation];
    if (!artwork) {
        artwork = [[NSImage imageNamed:@"PRLightAlbumArt.png"] TIFFRepresentation];
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:[NSString stringWithFormat:@"%@\n%@\n%@", formattedTime, artist, album]
                           notificationName:@"Playing Song"
                                   iconData:artwork
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
}

- (void)currentFileDidChange:(NSNotification *)notification {
    PRItem *item = [[_core now] currentItem];
    if (![[PRDefaults sharedDefaults] boolForKey:PRDefaultsPostGrowl] || !item) {
        return;
    }
    
    NSString *title = [[_db library] valueForItem:item attr:PRItemAttrTitle];
    NSString *artist = [[_db library] artistValueForItem:item];
    NSString *album = [[_db library] valueForItem:item attr:PRItemAttrAlbum];
    NSNumber *time = [[_db library] valueForItem:item attr:PRItemAttrTime];
    NSString *formattedTime = [[[PRTimeFormatter alloc] init] stringForObjectValue:time];
    NSData *artwork = [[[[_core db] albumArtController] artworkForItem:item] TIFFRepresentation];
    if (!artwork) {
        artwork = [[NSImage imageNamed:@"PRLightAlbumArt.png"] TIFFRepresentation];
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:[NSString stringWithFormat:@"%@\n%@\n%@", formattedTime, artist, album]
                           notificationName:@"Playing Song"
                                   iconData:artwork
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
}

@end
