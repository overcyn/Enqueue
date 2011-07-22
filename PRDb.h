#import <Cocoa/Cocoa.h>

@class sqlite3, sqlite3_stmt, PRHistory, PRLibrary, PRPlaylists, PRLibraryViewSource, PRNowPlayingViewSource, 
PRAlbumArtController, PRPlaybackOrder, PRQueue, PRResult, PRStatement;


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
// Initialization

- (BOOL)open;
- (void)create;
- (BOOL)update;
- (void)initialize;
- (BOOL)validate;

// ========================================
// Error

- (NSError *)databaseWasMovedError:(NSString *)newPath;
- (NSError *)databaseCouldNotBeInitializedError;
- (NSError *)errorForSQLiteResult:(int)result;
- (NSArray *)descriptionAndRecoveryForResultCode:(int)resultCode;

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
// Action

- (void)begin;
- (void)rollback;
- (void)commit;
- (NSArray *)executeString:(NSString *)string;
- (NSArray *)executeString:(NSString *)string withBindings:(NSDictionary *)bindings columns:(NSArray *)columns;
- (NSArray *)executeCachedString:(NSString *)string;
- (NSArray *)executeCachedString:(NSString *)string withBindings:(NSDictionary *)bindings columns:(NSArray *)columns;

- (BOOL)executeStatement:(NSString *)stmt _error:(NSError **)error;
- (BOOL)executeStatement:(NSString *)stmtString 
            withBindings:(NSDictionary *)dictionary
                  _error:(NSError **)error;
- (BOOL)executeStatement:(NSString *)stmt 
            withBindings:(NSDictionary *)bindings
                  result:(NSArray **)result
                  _error:(NSError **)error;

- (BOOL)count:(int *)count forTable:(NSString *)table _error:(NSError **)error;
- (BOOL)value:(id *)value  
    forColumn:(NSString *)column 
          row:(int)row 
		  key:(NSString *)key 
		table:(NSString *)table 
       _error:(NSError **)error;
- (BOOL)setValue:(id)value 
	   forColumn:(NSString *)column 
			 row:(int)row 
			 key:(NSString *)key 
		   table:(NSString *)table 
		  _error:(NSError **)error;

- (BOOL)intValue:(int *)value 
	   forColumn:(NSString *)column 
			 row:(int)row 
			 key:(NSString *)key 
		   table:(NSString *)table 
		  _error:(NSError **)error;
- (BOOL)setIntValue:(int)value 
		  forColumn:(NSString *)column 
				row:(int)row 
				key:(NSString *)key 
			  table:(NSString *)table 
			 _error:(NSError **)error;
@end

// ========================================
// PRStatement
// ========================================
@interface PRStatement : NSObject 
{
    sqlite3 *_sqlite3;
    sqlite3_stmt *_stmt;
    NSArray *_columnTypes;
    NSString *_statement;
}

- (id)initWithString:(NSString *)string db:(PRDb *)db;
+ (PRStatement *)statementWithString:(NSString *)string db:(PRDb *)db;

- (void)setBindings:(NSDictionary *)bindings;
- (void)setColumnTypes:(NSArray *)columnTypes;

- (NSArray *)execute;
+ (NSArray *)executeString:(NSString *)string withDb:(PRDb *)db bindings:(NSDictionary *)bindings columnTypes:(NSArray *)columnTypes;
+ (NSArray *)executeString:(NSString *)string withDb:(PRDb *)db;

@end

int no_case(void *udp, int lenA, const void *strA, int lenB, const void *strB);
CFRange PRFormatString(UniChar *string, int length);