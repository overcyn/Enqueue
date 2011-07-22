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
    
    NSString *title;
    [[[core db] library] value:&title forFile:file attribute:PRTitleFileAttribute _error:nil];
    NSString *artist;
    [[[core db] library] value:&artist forFile:file attribute:PRArtistFileAttribute _error:nil];
    NSString *album;
    [[[core db] library] value:&album forFile:file attribute:PRAlbumFileAttribute _error:nil];
    NSNumber *time;
    [[[core db] library] value:&time forFile:file attribute:PRTimeFileAttribute _error:nil];
    NSString *formattedTime = [[[[PRTimeFormatter alloc] init] autorelease] stringForObjectValue:time];
    
    NSImage *albumArt;
    [[[core db] albumArtController] albumArt:&albumArt forFile:file _error:nil];
    
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
