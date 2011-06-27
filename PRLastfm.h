#import <Foundation/Foundation.h>
#import "PRLibrary.h"

@class PRCore;

typedef enum {
    PRLastfmDisconnectedState,
    PRLastfmConnectedState,
    PRLastfmPendingState,
    PRLastfmValidatingState,
} PRLastfmState;

extern NSString * const PRLastfmStateDidChangeNotification;
extern NSString * const PRLastfmSecret;
extern NSString * const PRLastfmAPIKey;


@interface PRLastfm : NSObject
{
    // Accesssors
    NSString *cachedSessionKey;
    PRLastfmState lastfmState;
    NSString *error;
    
    // Scrobbling
    PRFile currentFile;
    NSDate *dateStarted;
    NSDate *datePlaying;
    NSTimeInterval playTime;
    
    // Authorization
    NSURLRequest *currentRequest;
    NSString *token;
    NSTimer *timer;
    
    PRCore *core;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Accessors

@property (readwrite, assign) NSString *error;
@property (readwrite) PRLastfmState lastfmState;
@property (readwrite, retain) NSString *username;

// ========================================
// Authorization

- (void)connect;
- (void)disconnect;

@end

@interface PRLastfm ()

// ========================================
// Accessors

@property (readwrite, retain) NSString *sessionKey;

// ========================================
// Scrobbling

- (void)scrobbleCurrentFile;
- (void)nowPlayingCurrentFile;
- (void)fileScrobbled:(NSData *)data request:(NSURLRequest *)request;

// ========================================
// Authorization

- (void)tokenGotten:(NSData *)data request:(NSURLRequest *)request;
- (void)getSession;
- (void)sessionGotten:(NSData *)data request:(NSURLRequest *)request;

// ========================================
// Misc

- (void)sendRequest:(NSURLRequest *)request completion:(SEL)completion;
- (NSURLRequest *)requestForParameters:(NSDictionary *)parameters;
- (NSString *)signatureForParameters:(NSDictionary *)parameters;

@end