#import "PRGrowl.h"
#import "Growl/Growl.h"
#import "PRNowPlayingController.h"
#import "PRUserDefaults.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRTimeFormatter.h"
#import "PRAlbumArtController.h"
#import "PRMoviePlayer.h"

@implementation PRGrowl

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super init])) {return nil;}
    core = core_;
    [GrowlApplicationBridge setGrowlDelegate:self];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(currentFileDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(playingChanged:)];
    return self;
}

- (void)playingChanged:(NSNotification *)notification
{
    BOOL isPlaying = [[[core now] mov] isPlaying];
    PRFile file = [[core now] currentFile];
    if (![[PRUserDefaults userDefaults] postGrowlNotification] || file == 0 || !isPlaying) {
        return;
    }
    NSString *title = [[[core db] library] valueForFile:file attribute:PRTitleFileAttribute];
    NSString *artist = [[[core db] library] valueForFile:file attribute:PRArtistFileAttribute];
    NSString *album = [[[core db] library] valueForFile:file attribute:PRAlbumFileAttribute];
    NSNumber *time = [[[core db] library] valueForFile:file attribute:PRTimeFileAttribute];
    NSString *formattedTime = [[[[PRTimeFormatter alloc] init] autorelease] stringForObjectValue:time];
    NSImage *albumArt = [[[core db] albumArtController] albumArtForFile:file];
    
    NSData *iconData = nil;
    if (albumArt) {
        iconData = [albumArt TIFFRepresentation];
    } else {
        iconData = [[NSImage imageNamed:@"PRLightAlbumArt.png"] TIFFRepresentation];
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:[NSString stringWithFormat:@"%@\n%@\n%@", formattedTime, artist, album]
                           notificationName:@"Playing Song"
                                   iconData:iconData
                                   priority:0
                                   isSticky:FALSE
                               clickContext:nil];
}

- (void)currentFileDidChange:(NSNotification *)notification
{
    PRFile file = [[core now] currentFile];
    if (![[PRUserDefaults userDefaults] postGrowlNotification] || file == 0) {
        return;
    }
    
    NSString *title = [[[core db] library] valueForFile:file attribute:PRTitleFileAttribute];
    NSString *artist = [[[core db] library] valueForFile:file attribute:PRArtistFileAttribute];
    NSString *album = [[[core db] library] valueForFile:file attribute:PRAlbumFileAttribute];
    NSNumber *time = [[[core db] library] valueForFile:file attribute:PRTimeFileAttribute];
    NSString *formattedTime = [[[[PRTimeFormatter alloc] init] autorelease] stringForObjectValue:time];
    NSImage *albumArt = [[[core db] albumArtController] albumArtForFile:file];
    
    NSData *iconData = nil;
    if (albumArt) {
        iconData = [albumArt TIFFRepresentation];
    } else {
        iconData = [[NSImage imageNamed:@"PRLightAlbumArt.png"] TIFFRepresentation];
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:[NSString stringWithFormat:@"%@\n%@\n%@", formattedTime, artist, album]
                           notificationName:@"Playing Song"
                                   iconData:iconData
                                   priority:0
                                   isSticky:FALSE
                               clickContext:nil];
}

@end
