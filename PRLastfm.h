#import <Foundation/Foundation.h>
#import "PRLibrary.h"
#import "PRLastfmFile.h"
@class PRCore;


typedef enum {
    PRLastfmDisconnectedState,
    PRLastfmConnectedState,
    PRLastfmPendingState,
    PRLastfmValidatingState,
} PRLastfmState;


@interface PRLastfm : NSObject {
    // Accesssors
    NSString *_cachedSessionKey;
    PRLastfmState _lastfmState;

    // Scrobbling
    PRLastfmFile *_file;    
    
    // Authorization
    NSURLRequest *_currentRequest;

    __weak PRCore *_core;
    __weak PRDb *_db;
}
// Initialization
- (id)initWithCore:(PRCore *)core;

// Accessors
- (PRLastfmState)lastfmState;
- (NSString *)username;

// Authorization
- (void)connect;
- (void)disconnect;
@end
