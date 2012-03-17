#import "PRLastfm.h"
#import <Security/Security.h>
#import "PRUserDefaults.h"
#import "EMKeychainItem.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "NSString+LFExtensions.h"
#import "NSURLConnection+Extensions.h"
#import "PRMoviePlayer.h"
#import "PRMainWindowController.h"

NSString * const PRLastfmSecret = @"7c36737d54802277880b10bf32fe8718";
NSString * const PRLastfmAPIKey = @"9e6a08d552a2e037f1ad598d5eca3802";


@interface PRLastfm ()
// Update
- (void)playingChanged:(NSNotification *)note;
- (void)playingFileChanged:(NSNotification *)note;

// Accessors
- (void)setLastfmState:(PRLastfmState)state;
- (void)setUsername:(NSString *)username;
- (NSString *)sessionKey;
- (void)setSessionKey:(NSString *)sessionKey;

// Scrobbling
- (void)scrobble:(PRLastfmFile *)lastfmFile;
- (void)nowPlaying:(PRLastfmFile *)lastfmFile;
- (void)fileScrobbled:(NSData *)data;

// Authorization
- (void)tokenGotten:(NSData *)data request:(NSURLRequest *)request;
- (void)getSession:(NSDictionary *)info;
- (void)sessionGotten:(NSData *)data request:(NSURLRequest *)request;

// Misc
- (NSURLRequest *)requestForParameters:(NSDictionary *)parameters;
- (NSString *)signatureForParameters:(NSDictionary *)parameters;
@end


@implementation PRLastfm

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core; {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [core db];
    _file = nil;
    // Get cached session key if exists
    BOOL connected = FALSE;
    if ([[self username] length] != 0) {
        EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService:@"Last.fm (com.enqueue.enqueue)" withUsername:[self username]];
        if (keychain && [keychain password]) {
            connected = TRUE;
            _cachedSessionKey = [[keychain password] retain];
        }
    }
    if (connected) {
        [self setLastfmState:PRLastfmConnectedState];
    } else {
        [self setLastfmState:PRLastfmDisconnectedState];
    }
    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(playingChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
    return self;
}

- (void)dealloc {
    [_cachedSessionKey release];
    [_file release];
    [super dealloc];
}

// ========================================
// Properties

- (void)setLastfmState:(PRLastfmState)state {
    _lastfmState = state;
    [[NSNotificationCenter defaultCenter] postLastfmStateChanged];
}

- (PRLastfmState)lastfmState {
    return _lastfmState;
}

- (void)setUsername:(NSString *)username {
    [[PRUserDefaults userDefaults] setLastFMUsername:username];
}

- (NSString *)username {
    return [[PRUserDefaults userDefaults] lastFMUsername];
}

- (void)setSessionKey:(NSString *)sessionKey {
    [_cachedSessionKey release];
    _cachedSessionKey = [sessionKey retain];
    if ([[self username] length] == 0) {
        return;
    }
    EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService:@"Last.fm (com.enqueue.enqueue)" withUsername:[self username]];
    if (keychain) {
        [keychain setPassword:sessionKey];
    } else {
        [EMGenericKeychainItem addGenericKeychainItemForService:@"Last.fm (com.enqueue.enqueue)" withUsername:[self username] password:sessionKey];
    }
}

- (NSString *)sessionKey {
    return _cachedSessionKey;
}

// ========================================
// Scrobbling

- (void)playingChanged:(NSNotification *)note {
    if ([[[_core now] mov] isPlaying]) {
        [_file play];
    } else {
        [_file pause];
    }
}

- (void)playingFileChanged:(NSNotification *)note {
    if (_file) {
        [self scrobble:_file];
    }
    [_file release];
    _file = nil;
    if ([[_core now] currentItem]) {
        _file = [[PRLastfmFile alloc] initWithItem:[[_core now] currentItem]];
        [_file play];
        [self nowPlaying:_file];
    }
}

- (void)nowPlaying:(PRLastfmFile *)lastfmFile {
    PRItem *item = [lastfmFile item];
    NSString *title = [[_db library] valueForItem:item attr:PRItemAttrTitle];
    NSString *artist = [[_db library] artistValueForItem:item];
    NSString *album = [[_db library] valueForItem:item attr:PRItemAttrAlbum];
    NSNumber *time = [[[_core db] library] valueForItem:item attr:PRItemAttrTime];
    
    if ([title length] == 0 || [artist length] == 0 || 
        [[self username] length] == 0 || [[self sessionKey] length] == 0) {
        return;
    }
    
    // Create request
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"track.updateNowPlaying", @"method",
                                       artist, @"artist",
                                       album, @"album",
                                       title, @"track",
                                       [NSString stringWithFormat:@"%li", (long)[time longValue]/1000], @"duration",
                                       PRLastfmAPIKey, @"api_key",
                                       [self sessionKey], @"sk", nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    void (^handler)(NSURLResponse*, NSData*, NSError*) = 
    ^(NSURLResponse *response, NSData *data, NSError *error) {};
	
	// Send request
    [_currentRequest release];
    _currentRequest = [request retain];
    [NSURLConnection send:request onCompletion:handler];
}

- (void)scrobble:(PRLastfmFile *)lastfmFile {
    PRItem *item = [lastfmFile item];
    NSString *title = [[_db library] valueForItem:item attr:PRItemAttrTitle];
    NSString *artist = [[_db library] artistValueForItem:item];
    NSString *album = [[_db library] valueForItem:item attr:PRItemAttrAlbum];
    NSNumber *time = [[[_core db] library] valueForItem:item attr:PRItemAttrTime];
    
    if (!([lastfmFile playTime] > [time intValue]/2000 || [lastfmFile playTime] > 240) ||
        [title length] == 0 || [artist length] == 0 || [time intValue]/1000 < 30 || 
        [[self username] length] == 0 || [[self sessionKey] length] == 0) {
        return;
    }
    
    // Create request
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"track.scrobble", @"method",
                                       [NSString stringWithFormat:@"%li",(long)[[lastfmFile startDate] timeIntervalSince1970]], @"timestamp[0]",
                                       artist, @"artist[0]",
                                       album, @"album[0]",
                                       title, @"track[0]",
                                       PRLastfmAPIKey, @"api_key",
                                       [self sessionKey], @"sk", nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    void (^handler)(NSURLResponse*, NSData*, NSError*) = 
    ^(NSURLResponse *response, NSData *data, NSError *error) {[self fileScrobbled:data];};
	
	// Send request
    [_currentRequest release];
    _currentRequest = [request retain];
    [NSURLConnection send:request onCompletion:handler];
}

- (void)fileScrobbled:(NSData *)data {
    if (!data) {
        return;
    }
    NSXMLDocument *XMLDocument = [[[NSXMLDocument alloc] initWithData:data options:0 error:nil] autorelease];
    NSXMLElement *root = [XMLDocument rootElement];
    if (![[[root attributeForName:@"status"] stringValue] isEqualToString:@"ok"]) {
        NSArray *errors = [root elementsForName:@"error"];
        if ([errors count] > 0 && [[[[errors objectAtIndex:0] attributeForName:@"code"] stringValue] isEqualToString:@"9"]) {
            NSLog(@"Last.fm Disconnected");
            [self disconnect];
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"You have been disconnected from Last.fm"];
            [alert setInformativeText:@"If this warning persists please contact support."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:[[_core win] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
    }
}

// ========================================
// Authorization

- (void)connect {
    [self disconnect];
    [self setLastfmState:PRLastfmValidatingState];
    // Create Request
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"auth.getToken", @"method",
                                       PRLastfmAPIKey, @"api_key", nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    void (^handler)(NSURLResponse*, NSData*, NSError*) = 
    ^(NSURLResponse *response, NSData *data, NSError *error) {
        [self tokenGotten:data request:request];
    };
    // Send Request
    [_currentRequest release];
    _currentRequest = [request retain];
    [NSURLConnection send:request onCompletion:handler];
}

- (void)tokenGotten:(NSData *)data request:(NSURLRequest *)request {
    if (request != _currentRequest) {
        return;
    }
    if (!data) {
        [self disconnect];
        return;
    }
    // Get token
    NSXMLDocument *XMLDocument = [[[NSXMLDocument alloc] initWithData:data options:0 error:nil] autorelease];
    if (![[[[XMLDocument rootElement] attributeForName:@"status"] stringValue] isEqualToString:@"ok"]) {
        [self disconnect];
        return;
    }
    NSString *token = [[[[XMLDocument rootElement] elementsForName:@"token"] objectAtIndex:0] stringValue];
    // Request authorization in webbrowser
    NSString *URLString = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@",PRLastfmAPIKey, token];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
    [self setLastfmState:PRLastfmPendingState];
    // Check for authorization in 5 seconds
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          request, @"request", token, @"token", nil];
    [self performSelector:@selector(getSession:) withObject:info afterDelay:5.0];
}

- (void)getSession:(NSDictionary *)info {
    NSString *token = [info objectForKey:@"token"];
    NSURLRequest *currentRequest = [info objectForKey:@"request"];
    if (currentRequest != _currentRequest) {
        return;
    }
    // Create Request
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"auth.getSession", @"method",
                                       token, @"token",
                                       PRLastfmAPIKey, @"api_key", nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    void (^handler)(NSURLResponse*, NSData*, NSError*) = 
    ^(NSURLResponse *response, NSData *data, NSError *error) {
        [self sessionGotten:data request:currentRequest];
        return;
    };
    // Send request
    [NSURLConnection send:request onCompletion:handler];
    // Recheck for authorization in 5 seconds
    [self performSelector:@selector(getSession:) withObject:info afterDelay:5.0];
}

- (void)sessionGotten:(NSData *)data request:(NSURLRequest *)request {
    if (request != _currentRequest) {
        return;
    }
    if (!data) {
        [self disconnect];
        return;
    }
    NSXMLDocument *XMLDocument = [[[NSXMLDocument alloc] initWithData:data options:0 error:nil] autorelease];
    if (![[[[XMLDocument rootElement] attributeForName:@"status"] stringValue] isEqualToString:@"ok"]) {
        return;
    }
    NSString *username = [[[[[[XMLDocument rootElement] elementsForName:@"session"] objectAtIndex:0] elementsForName:@"name"] objectAtIndex:0] stringValue];
    NSString *key = [[[[[[XMLDocument rootElement] elementsForName:@"session"] objectAtIndex:0] elementsForName:@"key"] objectAtIndex:0] stringValue];
    [self setUsername:username];
    [self setSessionKey:key];
    [self setLastfmState:PRLastfmConnectedState];
    [_currentRequest release];
    _currentRequest = nil;
}

- (void)disconnect {
    [self setUsername:@""];
    [self setSessionKey:@""];
    [_currentRequest release];
    _currentRequest = nil;
    [self setLastfmState:PRLastfmDisconnectedState];
}

// ========================================
// Misc

- (NSURLRequest *)requestForParameters:(NSDictionary *)parameters {
    NSURL *URL = [NSURL URLWithString:@"http://ws.audioscrobbler.com/2.0/"];
    NSMutableString *body = [NSMutableString string];
    for (NSString *i in [parameters allKeys]) {
        NSMutableString *escaped = [NSMutableString stringWithString:[parameters objectForKey:i]];
		[escaped replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
		[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
        [body appendFormat:@"%@=%@&", i, escaped];
    }
    [body deleteCharactersInRange:NSMakeRange([body length] - 1, 1)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                       timeoutInterval:5];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSString *)signatureForParameters:(NSDictionary *)parameters {
    NSArray *orderedKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *stringToSign = [NSMutableString string];
    for (NSString *i in orderedKeys) {
        [stringToSign appendFormat:@"%@%@", i, [parameters objectForKey:i]];
    }
    [stringToSign appendString:PRLastfmSecret];
    return [stringToSign MD5Hash];
}

@end
