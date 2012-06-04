#import "PRUserDefaults.h"
#import <Carbon/Carbon.h>
#import "PREQ.h"
#import "PRHotKeyController.h"


NSString * const PRDefaultsVolume = @"PRDefaultsVolume";
NSString * const PRDefaultsPregain = @"PRDefaultsPregain";
NSString * const PRDefaultsRepeat = @"PRDefaultsRepeat";
NSString * const PRDefaultsShuffle = @"PRDefaultsShuffle";
NSString * const PRDefaultsHogOutput = @"PRDefaultsHogOutput";

NSString * const PRDefaultsEQCustomArray = @"PRDefaultsEQCustomArray";
NSString * const PRDefaultsEQIsCustom = @"PRDefaultsEQIsCustom";
NSString * const PRDefaultsEQIndex = @"PRDefaultsEQIndex";
NSString * const PRDefaultsEQEnabled = @"PRDefaultsEQEnabled";

NSString * const PRDefaultsShowWelcomeSheet = @"PRDefaultsShowWelcomeSheet";
NSString * const PRDefaultsShowArtwork = @"PRDefaultsShowArtwork";
NSString * const PRDefaultsMiniPlayer = @"PRDefaultsMiniPlayer";
NSString * const PRDefaultsMiniPlayerFrame = @"PRDefaultsMiniPlayerFrame";
NSString * const PRDefaultsPlayerFrame = @"PRDefaultsSidebarWidth";
NSString * const PRDefaultsNowPlayingCollapseState = @"PRDefaultsNowPlayingCollapseState";

NSString * const PRDefaultsMediaKeys = @"PRDefaultsMediaKeys";
NSString * const PRDefaultsPostGrowl = @"PRDefaultsPostGrowl";
NSString * const PRDefaultsLastFMUsername = @"PRDefaultsLastFMUsername";
NSString * const PRDefaultsUseCompilation = @"PRDefaultsUseCompilation";
NSString * const PRDefaultsFolderArtwork = @"PRDefaultsFolderArtwork";

NSString * const PRDefaultsMonitoredFolders = @"PRDefaultsMonitoredFolders";
NSString * const PRDefaultsLastEventStreamEventId = @"PRDefaultsLastEventStreamEventId";


typedef id(^PRDefaultsHandlerGet)();
typedef void(^PRDefaultsHandlerSet)(id value);


@interface PRUserDefaults ()
+ (NSArray *)boolHandlersForKey:(NSString *)key defaultValue:(BOOL)value;
+ (NSArray *)floatHandlersForKey:(NSString *)key max:(float)max min:(float)min defaultValue:(float)defaultValue;
+ (NSArray *)intHandlersForKey:(NSString *)key max:(int)max min:(int)min defaultValue:(int)defaultValue;
+ (NSArray *)rectHandlersForKey:(NSString *)key defaultValue:(NSRect)defaultValue;
+ (NSArray *)stringHandlersForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
+ (NSArray *)archiverHandlersForKey:(NSString *)key class:(Class)class defaultValue:(id)defaultValue;

+ (NSArray *)EQCustomArrayHandlersForKey:(NSString *)key;
@end


@implementation PRUserDefaults

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:TRUE forKey:@"NSDisabledCharacterPaletteMenuItem"];
    
    _handlers = [[NSMutableDictionary alloc] init];
    [_handlers setValue:[PRUserDefaults floatHandlersForKey:@"volume" max:1.0f min:0.0f defaultValue:1.0f] forKey:PRDefaultsVolume];
    [_handlers setValue:[PRUserDefaults floatHandlersForKey:PRDefaultsPregain max:1.0f min:0.0f defaultValue:1.0f] forKey:PRDefaultsPregain];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsRepeat defaultValue:NO] forKey:PRDefaultsRepeat];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsShuffle defaultValue:NO] forKey:PRDefaultsShuffle];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsHogOutput defaultValue:NO] forKey:PRDefaultsHogOutput];
    
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsEQIsCustom defaultValue:NO] forKey:PRDefaultsEQIsCustom];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsEQEnabled defaultValue:NO] forKey:PRDefaultsEQEnabled];
    [_handlers setValue:[PRUserDefaults intHandlersForKey:PRDefaultsEQIndex max:0 min:0 defaultValue:0] forKey:PRDefaultsEQIndex];
    [_handlers setValue:[PRUserDefaults EQCustomArrayHandlersForKey:@"CustomEQs"] forKey:PRDefaultsEQCustomArray];
    
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsShowWelcomeSheet defaultValue:YES] forKey:PRDefaultsShowWelcomeSheet];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsShowArtwork defaultValue:YES] forKey:PRDefaultsShowArtwork];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsMiniPlayer defaultValue:NO] forKey:PRDefaultsMiniPlayer];
    [_handlers setValue:[PRUserDefaults rectHandlersForKey:PRDefaultsMiniPlayerFrame defaultValue:NSZeroRect] forKey:PRDefaultsMiniPlayerFrame];
    [_handlers setValue:[PRUserDefaults rectHandlersForKey:PRDefaultsPlayerFrame defaultValue:NSZeroRect] forKey:PRDefaultsPlayerFrame];
    [_handlers setValue:[PRUserDefaults archiverHandlersForKey:PRDefaultsNowPlayingCollapseState class:[NSIndexSet class] defaultValue:[NSIndexSet indexSet]]
                 forKey:PRDefaultsNowPlayingCollapseState];
    
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsMediaKeys defaultValue:YES] forKey:PRDefaultsMediaKeys];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsPostGrowl defaultValue:YES] forKey:PRDefaultsPostGrowl];
    [_handlers setValue:[PRUserDefaults stringHandlersForKey:PRDefaultsLastFMUsername defaultValue:YES] forKey:PRDefaultsLastFMUsername];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsUseCompilation defaultValue:YES] forKey:PRDefaultsUseCompilation];
    [_handlers setValue:[PRUserDefaults boolHandlersForKey:PRDefaultsFolderArtwork defaultValue:YES] forKey:PRDefaultsFolderArtwork];

    return self;
}

+ (id)userDefaults {
    return [[[PRUserDefaults alloc] init] autorelease];
}

+ (NSArray *)boolHandlersForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        if (![value isKindOfClass:[NSNumber class]]) {
            return [NSNumber numberWithBool:defaultValue];
        }
        return [NSNumber numberWithBool:[value boolValue]];
    };
    PRDefaultsHandlerSet setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)intHandlersForKey:(NSString *)key max:(int)max min:(int)min defaultValue:(int)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        if (![value isKindOfClass:[NSNumber class]] || (max != min && ([value intValue] < min || [value intValue] > max))) {
            return [NSNumber numberWithInt:defaultValue];
        }
        return [NSNumber numberWithInt:[value intValue]];
    };
    PRDefaultsHandlerSet setter = ^(id value){
        if ([value intValue] > max || [value intValue] < min) {
            value = [NSNumber numberWithInt:defaultValue];
        }
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)floatHandlersForKey:(NSString *)key max:(float)max min:(float)min defaultValue:(float)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        if (![value isKindOfClass:[NSNumber class]] || (max != min && ([value floatValue] < min || [value floatValue] > max))) {
            return [NSNumber numberWithFloat:defaultValue];
        }
        return [NSNumber numberWithFloat:[value floatValue]];
    };
    PRDefaultsHandlerSet setter = ^(id value){
        if ([value floatValue] > max || [value floatValue] < min) {
            value = [NSNumber numberWithFloat:defaultValue];
        }
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)rectHandlersForKey:(NSString *)key defaultValue:(NSRect)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (!value || ![value isKindOfClass:[NSString class]]) {
            return [NSValue valueWithRect:defaultValue];
        }
        return [NSValue valueWithRect:NSRectFromString(value)];
    };
    PRDefaultsHandlerSet setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect([value rectValue]) forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)stringHandlersForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
        id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            return (id)defaultValue;
        }
        return value;
    };
    PRDefaultsHandlerSet setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)archiverHandlersForKey:(NSString *)key class:(Class)class defaultValue:(id)defaultValue {
    PRDefaultsHandlerGet getter = (id)^{
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
    PRDefaultsHandlerSet setter = ^(id value){
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:key];
    };
    return @[getter, setter];
}

+ (NSArray *)EQCustomArrayHandlersForKey:(NSString *)key {
    PRDefaultsHandlerGet getter = (id)^{
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
    PRDefaultsHandlerSet setter = ^(id value){
        NSData *object = [NSKeyedArchiver archivedDataWithRootObject:value];
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    };
    return @[getter, setter];
}

#pragma mark - Accessors

- (id)valueForKey:(NSString *)key {
    return ((PRDefaultsHandlerGet)[[_handlers objectForKey:key] objectAtIndex:0])();
}

- (void)setValue:(id)value forKey:(NSString *)key {
    ((PRDefaultsHandlerSet)[[_handlers objectForKey:key] objectAtIndex:1])(value);
}

@dynamic volume;
@dynamic repeat;
@dynamic shuffle;
@dynamic preGain;
@dynamic hogOutput;

- (float)volume {
	NSNumber *object = [defaults objectForKey:@"volume"];
    if (![object isKindOfClass:[NSNumber class]] || [object floatValue] <= 1.0 || [object floatValue] >= 0.0) {
        return 1.0;
    }
    return [object floatValue];
}

- (void)setVolume:(float)volume {
    [defaults setObject:[NSNumber numberWithFloat:volume] forKey:@"volume"];
}

- (BOOL)repeat {
    NSNumber *object = [defaults objectForKey:@"repeat"];
    if (![object isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    return [object boolValue];
}

- (void)setRepeat:(BOOL)repeat {
    [defaults setObject:[NSNumber numberWithBool:repeat] forKey:@"repeat"];
}

- (BOOL)shuffle {
    NSNumber *object = [defaults objectForKey:@"shuffle"];
    if (![object isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    return [object boolValue];
}

- (void)setShuffle:(BOOL)shuffle {
    [defaults setObject:[NSNumber numberWithBool:shuffle] forKey:@"shuffle"];
}

- (float)preGain {
    return 0;
}

- (void)setPreGain:(float)preGain {
    [defaults setObject:[NSNumber numberWithFloat:preGain] forKey:@"preGain"];
}

- (BOOL)hogOutput {
    NSNumber *object = [defaults objectForKey:@"hogOutput"];
    if (![object isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    return [object boolValue];
}

- (void)setHogOutput:(BOOL)hogOutput {
    [defaults setObject:[NSNumber numberWithBool:hogOutput] forKey:@"hogOutput"];
}

@dynamic customEQs;
@dynamic isCustomEQ;
@dynamic EQIndex;
@dynamic EQIsEnabled;

- (NSArray *)customEQs {
    PREQ *defaultEQ = [PREQ flat];
    [defaultEQ setTitle:@"Custom"];
    NSArray *defaultEQArray = @[defaultEQ];
    
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
@dynamic nowPlayingCollapseState;

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

- (NSIndexSet *)nowPlayingCollapseState {
    id object = [defaults objectForKey:@"nowPlayingCollapseState"];
    if (!object || ![object isKindOfClass:[NSData class]]) {
        return [NSIndexSet indexSet];
    }
    
    id collapse = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    if (!collapse || ![collapse isKindOfClass:[NSIndexSet class]]) {
        return [NSIndexSet indexSet];
    }
    return collapse;
}

- (void)setNowPlayingCollapseState:(NSIndexSet *)nowPlayingCollapseState {
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:nowPlayingCollapseState] forKey:@"nowPlayingCollapseState"];
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
        return @[];
    }
    
    id monitoredFolders = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    if (!monitoredFolders || ![monitoredFolders isKindOfClass:[NSArray class]]) {
        return @[];
    }
    
    for (id i in monitoredFolders) {
        if (![i isKindOfClass:[NSURL class]]) {
            return @[];
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

- (void)setKeyMask:(unsigned int)mask keyCode:(int)code forHotKey:(int)hotKey {
    for (NSDictionary *i in [PRUserDefaults hotKeys]) {
        if ([[i objectForKey:@"hotKey"] intValue] == hotKey) {
            [defaults setObject:@{@"code":[NSNumber numberWithInt:code], @"keyMask":[NSNumber numberWithInt:mask]}
                         forKey:[i objectForKey:@"userDefaultsKey"]];
            return;
        }
    }
}

- (void)keyMask:(unsigned int *)mask keyCode:(int *)code forHotKey:(int)hotKey {
    NSDictionary *dict = nil;
    for (NSDictionary *i in [PRUserDefaults hotKeys]) {
        if ([[i objectForKey:@"hotKey"] intValue] == hotKey) {
            *mask = [[i objectForKey:@"keyMask"] intValue];
            *code = [[i objectForKey:@"code"] intValue];
            dict = [defaults objectForKey:[i objectForKey:@"userDefaultsKey"]];
            break;
        }
    }
    
    if (![dict isKindOfClass:[NSDictionary class]] || [[dict objectForKey:@"code"] isKindOfClass:[NSNumber class]]
        || ![[dict objectForKey:@"keyMask"] isKindOfClass:[NSNumber class]]) {
        return;
    }
    *mask = [[dict objectForKey:@"keyMask"] unsignedIntValue];
    *code = [[dict objectForKey:@"code"] intValue];
}

+ (NSArray *)hotKeys {
    static NSMutableArray *array = nil;
    if (!array) {
        array = [[NSMutableArray alloc] init];
        
        typedef struct {
            int hotKey;
            int defaultKeyMask;
            int defaultKeyCode;
            NSString *userDefaultsKey;
        } properties;
        properties p[] = {
            {PRPlayPauseHotKey, 49, cmdKey+optionKey+controlKey, @"playPauseHotKey"},
        };
        
        for (int i = 0; i < (sizeof(p)/sizeof(properties)); i++) {
            [array addObject:@{@"hotKey":[NSNumber numberWithInt:p[i].hotKey],
                               @"keyMask":[NSNumber numberWithInt:p[i].defaultKeyMask], 
                               @"code":[NSNumber numberWithInt:p[i].defaultKeyCode], 
                               @"userDefaultsKey":p[i].userDefaultsKey}];
        }
    }
    return array;
}

@end
