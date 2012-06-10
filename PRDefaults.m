#import "PRDefaults.h"
#import <Carbon/Carbon.h>
#import "PREQ.h"
#import "PRHotKeyController.h"


NSString * const PRDefaultsUseAlbumArtist = @"PRDefaultsUseAlbumArtist";
NSString * const PRDefaultsUseCompilation = @"PRDefaultsUseCompilation";
NSString * const PRDefaultsFolderArtwork = @"PRDefaultsFolderArtwork";

NSString * const PRDefaultsMonitoredFolders = @"PRDefaultsMonitoredFolders";
NSString * const PRDefaultsLastEventStreamEventId = @"PRDefaultsLastEventStreamEventId";

NSString * const PRDefaultsPostGrowl = @"PRDefaultsPostGrowl";

NSString * const PRDefaultsLastFMUsername = @"PRDefaultsLastFMUsername";

NSString * const PRDefaultsShowWelcomeSheet = @"PRDefaultsShowWelcomeSheet";
NSString * const PRDefaultsShowArtwork = @"PRDefaultsShowArtwork";
NSString * const PRDefaultsMiniPlayer = @"PRDefaultsMiniPlayer";
NSString * const PRDefaultsMiniPlayerFrame = @"PRDefaultsMiniPlayerFrame";
NSString * const PRDefaultsPlayerFrame = @"PRDefaultsPlayerFrame";
NSString * const PRDefaultsSidebarWidth = @"PRDefaultsSidebarWidth";
NSString * const PRDefaultsNowPlayingCollapseState = @"PRDefaultsNowPlayingCollapseState";

NSString * const PRDefaultsMediaKeys = @"PRDefaultsMediaKeys";
NSString * const PRDefaultsPlayPauseHotKey = @"PRDefaultsPlayPauseHotKey";
NSString * const PRDefaultsNextHotKey = @"PRDefaultsNextHotKey";
NSString * const PRDefaultsPreviousHotKey = @"PRDefaultsPreviousHotKey";
NSString * const PRDefaultsIncreaseVolumeHotKey = @"PRDefaultsIncreaseVolumeHotKey";
NSString * const PRDefaultsDecreaseVolumeHotKey = @"PRDefaultsDecreaseVolumeHotKey";
NSString * const PRDefaultsRate0HotKey = @"PRDefaultsRate0HotKey";
NSString * const PRDefaultsRate1HotKey = @"PRDefaultsRate1HotKey";
NSString * const PRDefaultsRate2HotKey = @"PRDefaultsRate2HotKey";
NSString * const PRDefaultsRate3HotKey = @"PRDefaultsRate3HotKey";
NSString * const PRDefaultsRate4HotKey = @"PRDefaultsRate4HotKey";
NSString * const PRDefaultsRate5HotKey = @"PRDefaultsRate5HotKey";

NSString * const PRDefaultsVolume = @"PRDefaultsVolume";
NSString * const PRDefaultsPregain = @"PRDefaultsPregain";
NSString * const PRDefaultsHogOutput = @"PRDefaultsHogOutput";
NSString * const PRDefaultsEQCurrent = @"PRDefaultsEQCurrent";
NSString * const PRDefaultsOutputDeviceUID = @"PRDefaultsOutputDeviceUID";

NSString * const PRDefaultsRepeat = @"PRDefaultsRepeat";
NSString * const PRDefaultsShuffle = @"PRDefaultsShuffle";

NSString * const PRDefaultsEQCustomArray = @"PRDefaultsEQCustomArray";
NSString * const PRDefaultsEQIsCustom = @"PRDefaultsEQIsCustom";
NSString * const PRDefaultsEQIndex = @"PRDefaultsEQIndex";
NSString * const PRDefaultsEQEnabled = @"PRDefaultsEQEnabled";

typedef id(^PRDefaultsGetter)();
typedef void(^PRDefaultsSetter)(id value);


@interface PRDefaults ()
+ (NSArray *)objectHandlersForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
+ (NSArray *)numberHandlersForKey:(NSString *)key max:(NSNumber *)max min:(NSNumber *)min defaultValue:(NSNumber *)defaultValue;
+ (NSArray *)numberHandlersForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue;
+ (NSArray *)rectHandlersForKey:(NSString *)key defaultValue:(NSRect)defaultValue;
+ (NSArray *)stringHandlersForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
+ (NSArray *)archiverHandlersForKey:(NSString *)key class:(Class)class defaultValue:(id)defaultValue;

+ (NSArray *)EQCustomArrayHandlersForKey:(NSString *)key;
+ (NSArray *)monitoredFoldersHandlersForKey:(NSString *)key;
+ (NSArray *)EQCurrentHandlers;
+ (NSArray *)EQIndexHandlersForKey:(NSString *)key;
+ (NSArray *)hotKeyHandlersForKey:(NSString *)key defaultValue:(NSArray *)defaultValue;
@end


@implementation PRDefaults

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:TRUE forKey:@"NSDisabledCharacterPaletteMenuItem"];
    
    NSNumber *mask = [NSNumber numberWithUnsignedInt:cmdKey+optionKey+controlKey];
    _handlers = [@{
        PRDefaultsUseAlbumArtist:[PRDefaults numberHandlersForKey:@"usesAlbumArt" defaultValue:@TRUE],
        PRDefaultsUseCompilation:[PRDefaults numberHandlersForKey:@"useCompilation" defaultValue:@TRUE],
        PRDefaultsFolderArtwork:[PRDefaults numberHandlersForKey:@"folderArtwork" defaultValue:@TRUE],

        PRDefaultsMonitoredFolders:[PRDefaults monitoredFoldersHandlersForKey:@"monitoredFolders"],
        PRDefaultsLastEventStreamEventId:[PRDefaults numberHandlersForKey:@"lastEventStreamEventIdea" defaultValue:@TRUE],

        PRDefaultsPostGrowl:[PRDefaults numberHandlersForKey:@"postGrowlNotification" defaultValue:@TRUE],

        PRDefaultsLastFMUsername:[PRDefaults stringHandlersForKey:@"lastFMUsername" defaultValue:@""],

        PRDefaultsShowWelcomeSheet:[PRDefaults numberHandlersForKey:@"showsWelcomeSheet" defaultValue:@TRUE],
        PRDefaultsShowArtwork:[PRDefaults numberHandlersForKey:@"showsArtwork" defaultValue:@TRUE],
        PRDefaultsMiniPlayer:[PRDefaults numberHandlersForKey:@"miniPlayer" defaultValue:@TRUE],
        PRDefaultsMiniPlayerFrame:[PRDefaults rectHandlersForKey:@"miniPlayerFrame" defaultValue:NSZeroRect],
        PRDefaultsPlayerFrame:[PRDefaults rectHandlersForKey:@"playerFrame" defaultValue:NSZeroRect],
        PRDefaultsSidebarWidth:[PRDefaults numberHandlersForKey:@"sidebarWidth" defaultValue:@185.0f],
        PRDefaultsNowPlayingCollapseState:[PRDefaults archiverHandlersForKey:@"nowPlayingCollapseState" class:[NSIndexSet class] defaultValue:[NSIndexSet indexSet]],

        PRDefaultsMediaKeys:[PRDefaults numberHandlersForKey:@"mediaKeys" defaultValue:@TRUE],
        PRDefaultsPlayPauseHotKey:[PRDefaults hotKeyHandlersForKey:@"playPauseHotKey" defaultValue:@[mask, @49]],
        PRDefaultsNextHotKey:[PRDefaults hotKeyHandlersForKey:@"playNextHotKey" defaultValue:@[mask, @124]],
        PRDefaultsPreviousHotKey:[PRDefaults hotKeyHandlersForKey:@"playPreviousHotKey" defaultValue:@[mask, @123]],
        PRDefaultsIncreaseVolumeHotKey:[PRDefaults hotKeyHandlersForKey:@"increaseVolumeHotKey" defaultValue:@[mask, @126]],
        PRDefaultsDecreaseVolumeHotKey:[PRDefaults hotKeyHandlersForKey:@"decreaseVolumeHotKey" defaultValue:@[mask, @125]],
        PRDefaultsRate0HotKey:[PRDefaults hotKeyHandlersForKey:@"rate0StarHotKey" defaultValue:@[mask, @17]],
        PRDefaultsRate1HotKey:[PRDefaults hotKeyHandlersForKey:@"rate1StarHotKey" defaultValue:@[mask, @18]],
        PRDefaultsRate2HotKey:[PRDefaults hotKeyHandlersForKey:@"rate2StarHotKey" defaultValue:@[mask, @19]],
        PRDefaultsRate3HotKey:[PRDefaults hotKeyHandlersForKey:@"rate3StarHotKey" defaultValue:@[mask, @20]],
        PRDefaultsRate4HotKey:[PRDefaults hotKeyHandlersForKey:@"rate4StarHotKey" defaultValue:@[mask, @21]],
        PRDefaultsRate5HotKey:[PRDefaults hotKeyHandlersForKey:@"rate5StarHotKey" defaultValue:@[mask, @23]],

        PRDefaultsVolume:[PRDefaults numberHandlersForKey:@"volume" max:@1.0f min:@0.0f defaultValue:@1.0f],
        PRDefaultsPregain:[PRDefaults numberHandlersForKey:@"preGain" max:@1.0f min:@0.0f defaultValue:@1.0f],
        PRDefaultsHogOutput:[PRDefaults numberHandlersForKey:@"hogOutput" defaultValue:@FALSE],
        PRDefaultsEQCurrent:[PRDefaults EQCurrentHandlers],
        PRDefaultsOutputDeviceUID:[PRDefaults stringHandlersForKey:PRDefaultsOutputDeviceUID defaultValue:nil],

        PRDefaultsRepeat:[PRDefaults numberHandlersForKey:@"repeat" defaultValue:@FALSE],
        PRDefaultsShuffle:[PRDefaults numberHandlersForKey:@"shuffle" defaultValue:@FALSE],
        
        PRDefaultsEQCustomArray:[PRDefaults EQCustomArrayHandlersForKey:@"CustomEQs"],
        PRDefaultsEQIsCustom:[PRDefaults numberHandlersForKey:@"isCustomEQ" defaultValue:@FALSE],
        PRDefaultsEQIndex:[PRDefaults EQIndexHandlersForKey:@"EQIndex"],
        PRDefaultsEQEnabled:[PRDefaults numberHandlersForKey:@"EQIsEnabled" defaultValue:@FALSE]} retain];
    return self;
}

+ (id)sharedDefaults {
    static dispatch_once_t once;
    static PRDefaults *sharedDefaults;
    dispatch_once(&once, ^ {sharedDefaults = [[PRDefaults alloc] init];});
    return sharedDefaults;
}

#pragma mark - Accessors

- (id)valueForKey:(NSString *)key {
    PRDefaultsGetter handler = [[_handlers objectForKey:key] objectAtIndex:0];
    if (!handler) {
        @throw NSInvalidArgumentException;
    }
    return handler();
}

- (void)setValue:(id)value forKey:(NSString *)key {
    PRDefaultsSetter handler = [[_handlers objectForKey:key] objectAtIndex:1];
    if (!handler) {
        @throw NSInvalidArgumentException;
    }
    handler(value);
}

- (BOOL)boolForKey:(NSString *)key {
    return [[self valueForKey:key] boolValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    return [self setValue:[NSNumber numberWithBool:value] forKey:key];
}

- (int)intForKey:(NSString *)key {
    return [[self valueForKey:key] intValue];
}

- (void)setInt:(int)value forKey:(NSString *)key {
    return [self setValue:[NSNumber numberWithInt:value] forKey:key];
}

- (float)floatForKey:(NSString *)key {
    return [[self valueForKey:key] floatValue];
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    return [self setValue:[NSNumber numberWithFloat:value] forKey:key];
}

- (NSRect)rectForKey:(NSString *)key {
    return [[self valueForKey:key] rectValue];
}

- (void)setRect:(NSRect)value forKey:(NSString *)key {
    [self setValue:[NSValue valueWithRect:value] forKey:key];
}

#pragma mark - Priv

+ (NSArray *)objectHandlersForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    PRDefaultsGetter getter = (id)^{
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    };
    PRDefaultsSetter setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)numberHandlersForKey:(NSString *)key max:(NSNumber *)max min:(NSNumber *)min defaultValue:(NSNumber *)defaultValue {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (![value isKindOfClass:[NSNumber class]] || (max && [max compare:value] == NSOrderedAscending) || (min && [min compare:value] == NSOrderedDescending)) {
            return defaultValue;
        }
        return (NSNumber *)value;
    };
    PRDefaultsSetter setter = ^(id value){
        if ((max && [max compare:value] == NSOrderedAscending) || (min && [min compare:value] == NSOrderedDescending)) {
            value = defaultValue;
        }
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)numberHandlersForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue {
    return [PRDefaults numberHandlersForKey:key max:nil min:nil defaultValue:defaultValue];
}

+ (NSArray *)rectHandlersForKey:(NSString *)key defaultValue:(NSRect)defaultValue {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!value || ![value isKindOfClass:[NSString class]]) {
            return [NSValue valueWithRect:defaultValue];
        }
        return [NSValue valueWithRect:NSRectFromString(value)];
    };
    PRDefaultsSetter setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect([value rectValue]) forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)stringHandlersForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            return (id)defaultValue;
        }
        return value;
    };
    PRDefaultsSetter setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)archiverHandlersForKey:(NSString *)key class:(Class)class defaultValue:(id)defaultValue {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!value || ![value isKindOfClass:[NSData class]]) {
            return defaultValue;
        }
        id unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:value];
        if (!unarchived || ![unarchived isKindOfClass:class]) {
            return unarchived;
        }
        return unarchived;
    };
    PRDefaultsSetter setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)EQCustomArrayHandlersForKey:(NSString *)key {
    PRDefaultsGetter getter = (id)^{
        PREQ *defaultEQ = [PREQ flat];
        [defaultEQ setTitle:@"Custom"];
        NSArray *defaultEQArray = @[defaultEQ];
        
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!value || ![value isKindOfClass:[NSData class]]) {
            return defaultEQArray;
        }
        
        NSArray *EQArray = [NSKeyedUnarchiver unarchiveObjectWithData:value];
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
    };
    PRDefaultsSetter setter = ^(id value){
        NSData *object = [NSKeyedArchiver archivedDataWithRootObject:value];
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)monitoredFoldersHandlersForKey:(NSString *)key {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!value || ![value isKindOfClass:[NSData class]]) {
            return @[];
        }
        id monitoredFolders = [NSKeyedUnarchiver unarchiveObjectWithData:value];
        if (!monitoredFolders || ![monitoredFolders isKindOfClass:[NSArray class]]) {
            return @[];
        }
        for (id i in monitoredFolders) {
            if (![i isKindOfClass:[NSURL class]]) {
                return @[];
            }
        }
        return (NSArray *)monitoredFolders;
    };
    PRDefaultsSetter setter = ^(id value){
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)EQCurrentHandlers {
    PRDefaultsGetter getter = (id)^{
        BOOL index = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
        if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom]) {
            return [[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray] objectAtIndex:index];
        } else {
            return [[PREQ defaultEQs] objectAtIndex:index];
        }
    };
    PRDefaultsSetter setter = ^(id value){
        @throw NSInvalidArgumentException;
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)EQIndexHandlersForKey:(NSString *)key {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (![value isKindOfClass:[NSNumber class]]) {
            return @0;
        }
        int EQIndex = [value intValue];
        bool EQIsCustom = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom];
        if (EQIndex < 0 ||
            (EQIsCustom && EQIndex >= [[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray] count]) ||
            (!EQIsCustom && EQIndex >= [[PREQ defaultEQs] count])) {
            return @0;
        }
        return (NSNumber *)value;
    };
    PRDefaultsSetter setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
}

+ (NSArray *)hotKeyHandlersForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    PRDefaultsGetter getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (![value isKindOfClass:[NSDictionary class]] || [[value objectForKey:@"code"] isKindOfClass:[NSNumber class]]
            || ![[value objectForKey:@"keyMask"] isKindOfClass:[NSNumber class]]) {
            return defaultValue;
        }
        return @[[value objectForKey:@"keyMask"], [value objectForKey:@"code"]];
    };
    PRDefaultsSetter setter = ^(id value){
        NSDictionary *object = @{@"keyMask":[value objectAtIndex:1], @"code":[value objectAtIndex:0]};
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    };
    return @[[[getter copy] autorelease], [[setter copy] autorelease]];
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
