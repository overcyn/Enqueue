#import "PRGrowl.h"
#import "Growl/Growl.h"
#import "PRNowPlayingController.h"
#import "PRUserDefaults.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRTimeFormatter.h"
#import "PRAlbumArtController.h"

@implementation PRGrowl

- (id)initWithCore:(PRCore *)core_
{
    if ((self = [super init])) {
        core = core_;
        [GrowlApplicationBridge setGrowlDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentFileDidChange:) name:PRCurrentFileDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)currentFileDidChange:(NSNotification *)notification
{
    if (![[PRUserDefaults userDefaults] postGrowlNotification]) {
        return;
    }
    
    PRFile file = [[core now] currentFile];
    if (file == 0) {
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
