#import "PRLastfm.h"
#import <Security/Security.h>
#import "PRUserDefaults.h"
#import "EMKeychainItem.h"
#import "EMKeychainProxy.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "NSString+LFExtensions.h"
#import "NSObject+Extensions.h"

NSString * const PRLastfmStateDidChangeNotification = @"PRLastfmStateDidChange";
NSString * const PRLastfmSecret = @"7c36737d54802277880b10bf32fe8718";
NSString * const PRLastfmAPIKey = @"9e6a08d552a2e037f1ad598d5eca3802";


@implementation PRLastfm

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_;
{
    if ((self = [super init])) {
        core = core_;
        cachedSessionKey = nil;
        if ([[self username] length] != 0 && [[self sessionKey] length] != 0) {
            [self setLastfmState:PRLastfmConnectedState];
        } else {
            [self setLastfmState:PRLastfmDisconnectedState];
        }
        
        [[[core now] mov] addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
        [[core now] addObserver:self forKeyPath:@"currentIndex" options:0 context:nil];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

// ========================================
// Properties
// ========================================

@synthesize lastfmState;
@synthesize error;

@dynamic username;
@dynamic sessionKey;

- (void)setUsername:(NSString *)username
{
    [[PRUserDefaults userDefaults] setLastFMUsername:username];
}

- (NSString *)username
{
    return [[PRUserDefaults userDefaults] lastFMUsername];
}

- (void)setSessionKey:(NSString *)sessionKey
{
    if ([[self username] length] != 0) {
        NSString *keychainService = [NSString stringWithFormat:@"Last.fm (%@)", [[NSBundle mainBundle] bundleIdentifier]];
        EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:keychainService withUsername:[self username]];
        if (keyItem) {
            [keyItem setPassword:sessionKey];
        } else {
            [[EMKeychainProxy sharedProxy] addGenericKeychainItemForService:keychainService withUsername:[self username] password:sessionKey];
        }
    }
    [cachedSessionKey autorelease];
    cachedSessionKey = [sessionKey retain];
}

- (NSString *)sessionKey
{
    NSString *sessionKey = @"";
    if (cachedSessionKey) {
        sessionKey = cachedSessionKey;
    } else if ([[self username] length] != 0) {
        NSString *keychainService = [NSString stringWithFormat:@"Last.fm (%@)", [[NSBundle mainBundle] bundleIdentifier]];
        EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:keychainService withUsername:[self username]];
        if (keyItem) {
            sessionKey = [keyItem password];
        }
    }
    [cachedSessionKey autorelease];
    cachedSessionKey = [sessionKey retain];
    return sessionKey;
}

// ========================================
// Scrobbling
// ========================================

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if (object == [core now] && [keyPath isEqualToString:@"currentIndex"]) {
        if (currentFile && datePlaying) {
            playTime += [[NSDate date] timeIntervalSinceDate:datePlaying];
            [self scrobbleCurrentFile];
        }
        
        currentFile = [[core now] currentFile];
        [dateStarted release];
        [datePlaying release];
        dateStarted = nil;
        datePlaying = nil;
        playTime = 0;
        if (currentFile != 0) {
            dateStarted = [[NSDate date] retain];
            datePlaying = [[NSDate date] retain];
            [self nowPlayingCurrentFile];
        }
    } else if (object == [[core now] mov] && [keyPath isEqualToString:@"isPlaying"]) {
        if (!currentFile) {
            return;
        }
        if ([[[core now] mov] isPlaying] && !datePlaying) {
            [datePlaying release];
            datePlaying = [[NSDate date] retain];
        } else if (![[[core now] mov] isPlaying] && datePlaying)  {
            playTime += [[NSDate date] timeIntervalSinceDate:datePlaying];
            [datePlaying release];
            datePlaying = nil;
        }
    }
}

- (void)nowPlayingCurrentFile
{
    NSString *title;
    NSString *artist;
    NSString *album;
    NSNumber *time;
    [[[core db] library] value:&title forFile:currentFile attribute:PRTitleFileAttribute _error:nil];
    [[[core db] library] value:&artist forFile:currentFile attribute:PRArtistFileAttribute _error:nil];
    [[[core db] library] value:&album forFile:currentFile attribute:PRAlbumFileAttribute _error:nil];
    [[[core db] library] value:&time forFile:currentFile attribute:PRTimeFileAttribute _error:nil];
        
    if (!title || !artist) {
        return;
    }
    if ([[self username] length] == 0 || [[self sessionKey] length] == 0) {
        return;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"track.updateNowPlaying", @"method",
                                       artist, @"artist",
                                       title, @"track",
                                       PRLastfmAPIKey, @"api_key",
                                       [self sessionKey], @"sk", nil];
    if (time) {
        [parameters setObject:[NSString stringWithFormat:@"%li", (long)[time longValue]/1000] forKey:@"duration"];
    }
    if (album) {
        [parameters setObject:album forKey:@"album[0]"];
    }
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    [currentRequest release];
    currentRequest = [request retain];
	
	// send request
    SEL selector = @selector(sendRequest:completion:);
    SEL p2 = @selector(fileScrobbled:request:);
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&request atIndex:2];
    [invocation setArgument:&p2 atIndex:3];
    [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
}

- (void)scrobbleCurrentFile
{
    NSString *title;
    NSString *artist;
    NSString *album;
    NSNumber *time;
    [[[core db] library] value:&title forFile:currentFile attribute:PRTitleFileAttribute _error:nil];
    [[[core db] library] value:&artist forFile:currentFile attribute:PRArtistFileAttribute _error:nil];
    [[[core db] library] value:&album forFile:currentFile attribute:PRAlbumFileAttribute _error:nil];
    [[[core db] library] value:&time forFile:currentFile attribute:PRTimeFileAttribute _error:nil];
    
    if (!(playTime > [time intValue]/2000 || playTime > 240)) {
        return;
    }
    if (!title || !artist || [time intValue]/1000 < 30) {
        return;
    }
    if ([[self username] length] == 0 || [[self sessionKey] length] == 0) {
        return;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"track.scrobble", @"method",
                                       [NSString stringWithFormat:@"%li",(long)[dateStarted timeIntervalSince1970]], @"timestamp[0]",
                                       artist, @"artist[0]",
                                       title, @"track[0]",
                                       PRLastfmAPIKey, @"api_key",
                                       [self sessionKey], @"sk", nil];
    if (album) {
        [parameters setObject:album forKey:@"album[0]"];
    }
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    [currentRequest release];
    currentRequest = [request retain];
	
	// send request
    SEL selector = @selector(sendRequest:completion:);
    SEL p2 = @selector(fileScrobbled:request:);
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&request atIndex:2];
    [invocation setArgument:&p2 atIndex:3];
    [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
}

- (void)fileScrobbled:(NSData *)data request:(NSURLRequest *)request
{
    
}

// ========================================
// Authorization
// ========================================

- (void)connect
{
    [self disconnect];
    
    [self setLastfmState:PRLastfmValidatingState];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"auth.getToken", @"method",
                                       PRLastfmAPIKey, @"api_key", nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    [currentRequest release];
    currentRequest = [request retain];
	
	// send request
    SEL selector = @selector(sendRequest:completion:);
    SEL p2 = @selector(tokenGotten:request:);
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&request atIndex:2];
    [invocation setArgument:&p2 atIndex:3];
    [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
}

- (void)tokenGotten:(NSData *)data request:(NSURLRequest *)request
{
    if (request != currentRequest) {
        [self disconnect];
        return;
    }
    
    // get token
    NSXMLDocument *XMLDocument = [[[NSXMLDocument alloc] initWithData:data options:0 error:nil] autorelease];
    if (![[[[XMLDocument rootElement] attributeForName:@"status"] stringValue] isEqualToString:@"ok"]) {
        [self disconnect];
        return;
    }
    [token release];
    token = [[[[[XMLDocument rootElement] elementsForName:@"token"] objectAtIndex:0] stringValue] retain];
    
    // request authorization in webbrowser
    NSString *URLString = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@",PRLastfmAPIKey, token];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
    [self setLastfmState:PRLastfmPendingState];
    
    [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(getSession) userInfo:nil repeats:TRUE] retain];
}

- (void)getSession
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"auth.getSession", @"method",
                                       token, @"token",
                                       PRLastfmAPIKey, @"api_key",
                                       nil];
    [parameters setObject:[self signatureForParameters:parameters] forKey:@"api_sig"];
    NSURLRequest *request = [self requestForParameters:parameters];
    [currentRequest release];
    currentRequest = [request retain];
    
    // send request
    SEL selector = @selector(sendRequest:completion:);
    SEL p2 = @selector(sessionGotten:request:);
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&request atIndex:2];
    [invocation setArgument:&p2 atIndex:3];
    [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
}

- (void)sessionGotten:(NSData *)data request:(NSURLRequest *)request
{
    if (request != currentRequest) {
        return;
    }
    
    NSXMLDocument *XMLDocument = [[[NSXMLDocument alloc] initWithData:data options:0 error:nil] autorelease];
    if (![[[[XMLDocument rootElement] attributeForName:@"status"] stringValue] isEqualToString:@"ok"]) {
        return;
    }
    [timer invalidate];
    NSString *username = [[[[[[XMLDocument rootElement] elementsForName:@"session"] objectAtIndex:0] elementsForName:@"name"] objectAtIndex:0] stringValue];
    NSString *key = [[[[[[XMLDocument rootElement] elementsForName:@"session"] objectAtIndex:0] elementsForName:@"key"] objectAtIndex:0] stringValue];
    [self setUsername:username];
    [self setSessionKey:key];
    [self setLastfmState:PRLastfmConnectedState];
}

- (void)disconnect
{
    [self setUsername:@""];
    [self setSessionKey:@""];
    
    [timer invalidate];
    [currentRequest release];
    currentRequest = nil;
    [self setLastfmState:PRLastfmDisconnectedState];
}


// ========================================
// Misc
// ========================================

- (void)sendRequest:(NSURLRequest *)request completion:(SEL)completion
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    SEL selector = completion;
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&data atIndex:2];
    [invocation setArgument:&request atIndex:3];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:FALSE];
    
    [pool drain];
}

- (NSURLRequest *)requestForParameters:(NSDictionary *)parameters
{
    NSURL *URL = [NSURL URLWithString:@"http://ws.audioscrobbler.com/2.0/"];
    NSMutableString *body = [NSMutableString string];
    for (NSString *i in [parameters allKeys]) {
        [body appendFormat:@"%@=%@&", i, [parameters objectForKey:i]];
    }
    [body deleteCharactersInRange:NSMakeRange([body length] - 1, 1)];
    NSString *body2 = [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                       timeoutInterval:5];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body2 dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSString *)signatureForParameters:(NSDictionary *)parameters
{
    NSArray *orderedKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *stringToSign = [NSMutableString string];
    for (NSString *i in orderedKeys) {
        [stringToSign appendFormat:@"%@%@", i, [parameters objectForKey:i]];
    }
    [stringToSign appendString:PRLastfmSecret];
    return [stringToSign MD5Hash];
}

@end
