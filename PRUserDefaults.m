#import "PRUserDefaults.h"
#import "PREQ.h"


@implementation PRUserDefaults

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:TRUE forKey:@"NSDisabledCharacterPaletteMenuItem"];
    return self;
}

+ (id)userDefaults {
    return [[[PRUserDefaults alloc] init] autorelease];
}

#pragma mark - Accessors

@dynamic volume;
@dynamic repeat;
@dynamic shuffle;
@dynamic preGain;

- (float)volume {
	NSNumber *object = [defaults objectForKey:@"volume"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object floatValue];
    } else {
        return 1;
    }
}

- (void)setVolume:(float)volume {
    [defaults setObject:[NSNumber numberWithFloat:volume] forKey:@"volume"];
}

- (BOOL)repeat {
    NSNumber *object = [defaults objectForKey:@"repeat"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return FALSE;
    }
}

- (void)setRepeat:(BOOL)repeat {
    [defaults setObject:[NSNumber numberWithBool:repeat] forKey:@"repeat"];
}

- (BOOL)shuffle {
    NSNumber *object = [defaults objectForKey:@"shuffle"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return FALSE;
    }
}

- (void)setShuffle:(BOOL)shuffle {
    [defaults setObject:[NSNumber numberWithBool:shuffle] forKey:@"shuffle"];
}

- (float)preGain {
    return 0;
    NSNumber *object = [defaults objectForKey:@"preGain"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object floatValue];
    } else {
        return 0;
    }
}

- (void)setPreGain:(float)preGain {
    [defaults setObject:[NSNumber numberWithFloat:preGain] forKey:@"preGain"];
}

@dynamic customEQs;
@dynamic isCustomEQ;
@dynamic EQIndex;
@dynamic EQIsEnabled;

- (NSArray *)customEQs {
    PREQ *defaultEQ = [PREQ flat];
    [defaultEQ setTitle:@"Custom"];
    NSArray *defaultEQArray = [NSArray arrayWithObjects:defaultEQ, nil];
    
    id object = [defaults objectForKey:@"CustomEQs"];
    if (!object || ![object isKindOfClass:[NSData class]]) {
        return defaultEQArray;
    }
    
    id EQArray = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    if (!EQArray || ![EQArray isKindOfClass:[NSArray class]]) {
        return defaultEQArray;
    }
    
    for (id i in EQArray) {
        if (![i isKindOfClass:[PREQ class]]) {
            return defaultEQArray;
        }
    }
    
    if ([EQArray count] < 1 || ![[(PREQ *)[EQArray objectAtIndex:0] title] isEqualToString:@"Custom"]) {
        return defaultEQArray;
    }
    return EQArray;
}

- (void)setCustomEQs:(NSArray *)customEQs {
    NSData *object = [NSKeyedArchiver archivedDataWithRootObject:customEQs];
    [defaults setObject:object forKey:@"CustomEQs"];
}

- (BOOL)isCustomEQ {
    NSNumber *object = [defaults objectForKey:@"isCustomEQ"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setIsCustomEQ:(BOOL)isCustomEQ {
    [defaults setObject:[NSNumber numberWithBool:isCustomEQ] forKey:@"isCustomEQ"];
}

- (int)EQIndex {
    int EQIndex;
    NSNumber *object = [defaults objectForKey:@"EQIndex"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        EQIndex = [object intValue];
    } else {
        EQIndex = 0;
    }
    
    if ([self isCustomEQ]) {
        if (EQIndex < 0 || EQIndex >= [[self customEQs] count]) {
            return 0;
        }
    } else {
        if (EQIndex < 0 || EQIndex >= [[PREQ defaultEQs] count]) {
            return 0;
        }
    }
    return EQIndex;
}

- (void)setEQIndex:(int)EQIndex {
    [defaults setObject:[NSNumber numberWithInt:EQIndex] forKey:@"EQIndex"];
}

- (BOOL)EQIsEnabled {
    NSNumber *object = [defaults objectForKey:@"EQIsEnabled"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return FALSE;
    }
}

- (void)setEQIsEnabled:(BOOL)EQisEnabled {
    [defaults setObject:[NSNumber numberWithBool:EQisEnabled] forKey:@"EQIsEnabled"];
}

@dynamic showWelcomeSheet;
@dynamic miniPlayer;
@dynamic miniPlayerFrame;
@dynamic playerFrame;
@dynamic sidebarWidth;

- (BOOL)showWelcomeSheet {
    NSNumber *object = [defaults objectForKey:@"showsWelcomeSheet"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setShowWelcomeSheet:(BOOL)showsWelcomeSheet {
    [defaults setObject:[NSNumber numberWithBool:showsWelcomeSheet] forKey:@"showsWelcomeSheet"];
}

- (BOOL)miniPlayer {
    NSNumber *object = [defaults objectForKey:@"miniPlayer"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return FALSE;
    }
}

- (void)setMiniPlayer:(BOOL)miniPlayer {
    [defaults setObject:[NSNumber numberWithBool:miniPlayer] forKey:@"miniPlayer"];
}

- (NSRect)miniPlayerFrame {
    NSString *object = [defaults objectForKey:@"miniPlayerFrame"];
    if (object && [object isKindOfClass:[NSString class]]) {
        return NSRectFromString(object);
    } else {
        return NSZeroRect;
    }
}

- (void)setMiniPlayerFrame:(NSRect)miniPlayerFrame {
    [defaults setObject:NSStringFromRect(miniPlayerFrame) forKey:@"miniPlayerFrame"];
}

- (NSRect)playerFrame {
    NSString *object = [defaults objectForKey:@"playerFrame"];
    if (object && [object isKindOfClass:[NSString class]]) {
        return NSRectFromString(object);
    } else {
        return NSZeroRect;
    }
}

- (void)setPlayerFrame:(NSRect)playerFrame {
    [defaults setObject:NSStringFromRect(playerFrame) forKey:@"playerFrame"];
}

- (float)sidebarWidth {
    NSNumber *object = [defaults objectForKey:@"sidebarWidth"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object floatValue];
    } else {
        return 185;
    }
}

- (void)setSidebarWidth:(float)sidebarWidth {
    [defaults setObject:[NSNumber numberWithFloat:sidebarWidth] forKey:@"sidebarWidth"];
}

@dynamic mediaKeys;
@dynamic postGrowlNotification;
@dynamic lastFMUsername;
@dynamic showsArtwork;
@dynamic useAlbumArtist;
@dynamic useCompilation;
@dynamic nowPlayingCollapsible;
@dynamic folderArtwork;

- (BOOL)mediaKeys {
    NSNumber *object = [defaults objectForKey:@"mediaKeys"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setMediaKeys:(BOOL)mediaKeys {
    [defaults setObject:[NSNumber numberWithBool:mediaKeys] forKey:@"mediaKeys"];
}

- (BOOL)postGrowlNotification {
    NSNumber *object = [defaults objectForKey:@"postGrowlNotification"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setPostGrowlNotification:(BOOL)postGrowlNotification {
    [defaults setObject:[NSNumber numberWithBool:postGrowlNotification] forKey:@"postGrowlNotification"];
}

- (NSString *)lastFMUsername {
    NSString *object = [defaults objectForKey:@"lastFMUsername"];
    if (object && [object isKindOfClass:[NSString class]]) {
        return object;
    } else {
        return @"";
    }
}

- (void)setLastFMUsername:(NSString *)lastFMUsername {
    [defaults setObject:lastFMUsername forKey:@"lastFMUsername"];
}

- (BOOL)showsArtwork {
    NSNumber *object = [defaults objectForKey:@"showsArtwork"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setShowsArtwork:(BOOL)showsArtwork {
    [defaults setObject:[NSNumber numberWithBool:showsArtwork] forKey:@"showsArtwork"];
}

- (BOOL)useAlbumArtist {
    NSNumber *object = [defaults objectForKey:@"usesAlbumArt"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setUseAlbumArtist:(BOOL)usesAlbumArt {
    [defaults setObject:[NSNumber numberWithBool:usesAlbumArt] forKey:@"usesAlbumArt"];
}

- (BOOL)useCompilation {
    NSNumber *object = [defaults objectForKey:@"useCompilation"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setUseCompilation:(BOOL)useCompilation {
    [defaults setObject:[NSNumber numberWithBool:useCompilation] forKey:@"useCompilation"];
}

- (BOOL)nowPlayingCollapsible {
    NSNumber *object = [defaults objectForKey:@"nowPlayingCollapsible"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setNowPlayingCollapsible:(BOOL)nowPlayingCollapsible {
    [defaults setObject:[NSNumber numberWithBool:nowPlayingCollapsible] forKey:@"nowPlayingCollapsible"];
}

- (BOOL)folderArtwork {
    NSNumber *object = [defaults objectForKey:@"folderArtwork"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setFolderArtwork:(BOOL)folderArtwork {
    [defaults setObject:[NSNumber numberWithBool:folderArtwork] forKey:@"folderArtwork"];
}

@dynamic monitoredFolders;
@dynamic lastEventStreamEventId;

- (NSArray *)monitoredFolders {
    id object = [defaults objectForKey:@"monitoredFolders"];
    if (!object || ![object isKindOfClass:[NSData class]]) {
        return [NSArray array];
    }
    
    id monitoredFolders = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    if (!monitoredFolders || ![monitoredFolders isKindOfClass:[NSArray class]]) {
        return [NSArray array];
    }
    
    for (id i in monitoredFolders) {
        if (![i isKindOfClass:[NSURL class]]) {
            return [NSArray array];
        }
    }
    return monitoredFolders;
}

- (void)setMonitoredFolders:(NSArray *)monitoredFolders {
    NSData *object = [NSKeyedArchiver archivedDataWithRootObject:monitoredFolders];
    [defaults setObject:object forKey:@"monitoredFolders"];
}

- (FSEventStreamEventId)lastEventStreamEventId {
    NSNumber *object = [defaults objectForKey:@"lastEventStreamEventIdea"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object unsignedLongLongValue];
    } else {
        return 0;
    }
}

- (void)setLastEventStreamEventId:(FSEventStreamEventId)lastEventStreamEventId {
    [defaults setObject:[NSNumber numberWithUnsignedLongLong:lastEventStreamEventId] 
                 forKey:@"lastEventStreamEventIdea"];
}

@dynamic applicationSupportPath;
@dynamic libraryPath;
@dynamic backupPath;
@dynamic cachedAlbumArtPath;
@dynamic downloadedAlbumArtPath;
@dynamic tempArtPath;

- (NSString *)applicationSupportPath {
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:executableName];
    return path;
}

- (NSString *)libraryPath {
    NSString *path = [[self applicationSupportPath] stringByAppendingPathComponent:@"Enqueue.db"];
    return path;
}

- (NSString *)backupPath {
    NSString *path = [[self applicationSupportPath] stringByAppendingPathComponent:@"Backup"];
    return path;
}

- (NSString *)cachedAlbumArtPath {
	NSString *albumArtPath = [[self libraryPath] stringByDeletingLastPathComponent];
	return [albumArtPath stringByAppendingPathComponent:@"Cached Album Art"];
}

- (NSString *)downloadedAlbumArtPath {
	NSString *albumArtPath = [[self libraryPath] stringByDeletingLastPathComponent];
	return [albumArtPath stringByAppendingPathComponent:@"Downloaded Album Art"];
}

- (NSString *)tempArtPath {
    return [[self cachedAlbumArtPath] stringByAppendingPathComponent:@"Temporary Art"];
}

@end
