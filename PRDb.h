#import <Cocoa/Cocoa.h>

#ifndef _SQLITE3_H_
@class sqlite3, sqlite3_stmt;
#endif

@class PRHistory, PRLibrary, PRPlaylists, PRLibraryViewSource, PRNowPlayingViewSource, 
PRAlbumArtController, PRPlaybackOrder, PRQueue, PRResult, PRStatement, PRReturnTypes, PRBindings;


// ========================================
// Constants & Typedefs

extern NSString * const PRLibraryDidChangeNotification;
extern NSString * const PRTagsDidChangeNotification;
extern NSString * const PRLibraryViewDidChangeNotification;
extern NSString * const PRPlaylistDidChangeNotification;
extern NSString * const PRPlaylistsDidChangeNotification;
extern NSString * const PRFilePboardType;
extern NSString * const PRIndexesPboardType;

typedef enum {PRColumnInteger, PRColumnFloat, PRColumnString, PRColumnData} PRColumn;

// ========================================
// PRDb
// ========================================
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

int no_case(void *udp, int lenA, const void *strA, int lenB, const void *strB);
CFRange PRFormatString(UniChar *string, int length);
