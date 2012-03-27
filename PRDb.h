#import <Cocoa/Cocoa.h>
#include "sqlite3.h"
@class PRHistory, PRLibrary, PRPlaylists, PRLibraryViewSource, PRNowPlayingViewSource, PRAlbumArtController, PRPlaybackOrder, PRQueue, PRStatement, PRCore;


extern NSString * const PRFilePboardType;
extern NSString * const PRIndexesPboardType;

typedef NSString PRCol;
extern NSString * const PRColFloat;
extern NSString * const PRColInteger;
extern NSString * const PRColString;
extern NSString * const PRColData;


@interface PRDb : NSObject {
	sqlite3 *sqlDb;
	PRHistory *history;
	PRLibrary *library;
	PRPlaylists *playlists;
    PRQueue *queue;
	PRLibraryViewSource *libraryViewSource;
	PRNowPlayingViewSource *nowPlayingViewSource;
    PRPlaybackOrder *playbackOrder;
	PRAlbumArtController *albumArtController;
    
    int transaction;
    NSMutableDictionary *_cachedStatements;
    
    __weak PRCore *_core;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readwrite, assign) sqlite3 *sqlDb;
@property (readonly) PRHistory *history;
@property (readonly) PRLibrary *library;
@property (readonly) PRPlaylists *playlists;
@property (readonly) PRLibraryViewSource *libraryViewSource;
@property (readonly) PRNowPlayingViewSource *nowPlayingViewSource;
@property (readonly) PRAlbumArtController *albumArtController;
@property (readonly) PRPlaybackOrder *playbackOrder;
@property (readonly) PRQueue *queue;
- (long)lastInsertRowid;

/* Action */
- (void)begin;
- (void)rollback;
- (void)commit;
- (NSArray *)execute:(NSString *)string;
- (NSArray *)execute:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns;
- (NSArray *)executeCached:(NSString *)string;
- (NSArray *)executeCached:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns;
- (NSArray *)attempt:(NSString *)string;
- (NSArray *)attempt:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns;

/* Error */
- (NSError *)databaseWasMovedError:(NSString *)newPath;
- (NSError *)databaseCouldNotBeMovedError;
- (NSError *)databaseCouldNotBeInitializedError;
@end
