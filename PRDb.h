#import <Cocoa/Cocoa.h>
#include "sqlite3.h"

@class PRHistory, PRLibrary, PRPlaylists, PRLibraryViewSource, PRNowPlayingViewSource, 
PRAlbumArtController, PRPlaybackOrder, PRQueue, PRStatement, PRCore;


// ========================================
// Constants & Typedefs

extern NSString * const PRFilePboardType;
extern NSString * const PRIndexesPboardType;

extern NSString * const PRColInteger;
extern NSString * const PRColFloat;
extern NSString * const PRColString;
extern NSString * const PRColData;

typedef enum {PRColumnInteger, PRColumnFloat, PRColumnString, PRColumnData} PRColumn;

// ========================================
// PRDb
// ========================================
@interface PRDb : NSObject {
    PRCore *_core;
    
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
}

// ========================================
// Properties

@property (readwrite, assign) sqlite3 *sqlDb;
@property (readonly) PRHistory *history;
@property (readonly) PRLibrary *library;
@property (readonly) PRPlaylists *playlists;
@property (readonly) PRLibraryViewSource *libraryViewSource;
@property (readonly) PRNowPlayingViewSource *nowPlayingViewSource;
@property (readonly) PRAlbumArtController *albumArtController;
@property (readonly) PRPlaybackOrder *playbackOrder;
@property (readonly) PRQueue *queue;

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core;
- (BOOL)open;
- (void)create;
- (BOOL)update;
- (BOOL)initialize;
- (BOOL)move:(NSError **)err;

// ========================================
// Action

- (void)begin;
- (void)rollback;
- (void)commit;

- (long)lastInsertRowid;

- (NSArray *)execute:(NSString *)string;
- (NSArray *)execute:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns;
- (NSArray *)attempt:(NSString *)string;
- (NSArray *)attempt:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns;

// ========================================
// Error

- (NSError *)databaseWasMovedError:(NSString *)newPath;
- (NSError *)databaseCouldNotBeMovedError;
- (NSError *)databaseCouldNotBeInitializedError;

@end

