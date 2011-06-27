#import "PRUserDefaults.h"

// ========================================
// Constants
// ========================================

NSString * const PRPreGainDidChangeNotification = @"PRPreGainDidChangeNotification";
NSString * const PRUseAlbumArtistDidChangeNotification = @"PRUseAlbumArtistDidChangeNotification";
static PRUserDefaults *sharedUserDefaults = nil;

@implementation PRUserDefaults

// ========================================
// Initialization
// ========================================

+ (PRUserDefaults *)sharedUserDefaults
{
    if (sharedUserDefaults == nil) {
        sharedUserDefaults = [[super allocWithZone:NULL] init];
    }
    return sharedUserDefaults;
}

- (id)init
{
    self = [super init];
	if (self) {
		defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:TRUE forKey:@"NSDisabledCharacterPaletteMenuItem"];
	}
	return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedUserDefaults] retain];   
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;   
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@dynamic showWelcomeSheet;
@dynamic showsArtwork;
@dynamic preGain;
@dynamic volume;
@dynamic postGrowlNotification;
@dynamic mediaKeys;
@dynamic lastFMUsername;
@dynamic useAlbumArtist;
@dynamic lastEventStreamEventId;
@dynamic monitoredFolders;

- (BOOL)showWelcomeSheet
{
    NSNumber *object = [defaults objectForKey:@"showsWelcomeSheet"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setShowWelcomeSheet:(BOOL)showsWelcomeSheet
{
    [defaults setObject:[NSNumber numberWithBool:showsWelcomeSheet] forKey:@"showsWelcomeSheet"];
}

- (float)volume
{
	NSNumber *object = [defaults objectForKey:@"volume"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object floatValue];
    } else {
        return 1;
    }
}

- (void)setVolume:(float)volume
{
    [defaults setObject:[NSNumber numberWithFloat:volume] forKey:@"volume"];
}

- (float)preGain
{
    NSNumber *object = [defaults objectForKey:@"preGain"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object floatValue];
    } else {
        return 0;
    }
}

- (void)setPreGain:(float)preGain
{
    [defaults setObject:[NSNumber numberWithFloat:preGain] forKey:@"preGain"];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPreGainDidChangeNotification object:self];
}

- (BOOL)showsArtwork
{
    NSNumber *object = [defaults objectForKey:@"showsArtwork"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setShowsArtwork:(BOOL)showsArtwork
{
    [defaults setObject:[NSNumber numberWithBool:showsArtwork] forKey:@"showsArtwork"];
}

- (BOOL)mediaKeys
{
    NSNumber *object = [defaults objectForKey:@"mediaKeys"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return FALSE;
    }
}

- (void)setMediaKeys:(BOOL)mediaKeys
{
    [defaults setObject:[NSNumber numberWithBool:mediaKeys] forKey:@"mediaKeys"];
}


- (BOOL)postGrowlNotification
{
    NSNumber *object = [defaults objectForKey:@"postGrowlNotification"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setPostGrowlNotification:(BOOL)postGrowlNotification
{
    [defaults setObject:[NSNumber numberWithBool:postGrowlNotification] forKey:@"postGrowlNotification"];
}

- (NSString *)lastFMUsername
{
    NSString *object = [defaults objectForKey:@"lastFMUsername"];
    if (object && [object isKindOfClass:[NSString class]]) {
        return object;
    } else {
        return @"";
    }
}

- (void)setLastFMUsername:(NSString *)lastFMUsername
{
    [defaults setObject:lastFMUsername forKey:@"lastFMUsername"];
}

- (BOOL)useAlbumArtist
{
    NSNumber *object = [defaults objectForKey:@"usesAlbumArt"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    } else {
        return TRUE;
    }
}

- (void)setUseAlbumArtist:(BOOL)usesAlbumArt
{
    [defaults setObject:[NSNumber numberWithBool:usesAlbumArt] forKey:@"usesAlbumArt"];
}

- (FSEventStreamEventId)lastEventStreamEventId
{
    NSNumber *object = [defaults objectForKey:@"lastEventStreamEventIdea"];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        return [object unsignedLongLongValue];
    } else {
        return 0;
    }
}

- (void)setLastEventStreamEventId:(FSEventStreamEventId)lastEventStreamEventId
{
    [defaults setObject:[NSNumber numberWithUnsignedLongLong:lastEventStreamEventId] 
                 forKey:@"lastEventStreamEventIdea"];
}

- (NSArray *)monitoredFolders
{
    NSData *object = [defaults objectForKey:@"monitoredFolders"];
    if (!object || ![object isKindOfClass:[NSData class]]) {
        return [NSArray array];
    }
    
    NSArray *monitoredFolders = [NSKeyedUnarchiver unarchiveObjectWithData:object];
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

- (void)setMonitoredFolders:(NSArray *)monitoredFolders
{
    NSData *object = [NSKeyedArchiver archivedDataWithRootObject:monitoredFolders];
    [defaults setObject:object forKey:@"monitoredFolders"];
}

@dynamic applicationSupportPath;
@dynamic libraryPath;
@dynamic cachedAlbumArtPath;
@dynamic downloadedAlbumArtPath;

- (NSString *)applicationSupportPath
{
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:executableName];
    return path;
}

- (NSString *)libraryPath
{
    NSString *path = [[self applicationSupportPath] stringByAppendingPathComponent:@"Enqueue.db"];
    return path;
}

- (NSString *)cachedAlbumArtPath
{
	NSString *albumArtPath = [[self libraryPath] stringByDeletingLastPathComponent];
	return [albumArtPath stringByAppendingPathComponent:@"Cached Album Art"];
}

- (NSString *)downloadedAlbumArtPath
{
	NSString *albumArtPath = [[self libraryPath] stringByDeletingLastPathComponent];
	return [albumArtPath stringByAppendingPathComponent:@"Downloaded Album Art"];
}

@end
