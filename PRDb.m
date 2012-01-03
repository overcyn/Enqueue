#import "PRCore.h"
#import "PRDb.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRLibraryViewSource.h"
#import "PRNowPlayingViewSource.h"
#import "PRAlbumArtController.h"
#import "PRPlaybackOrder.h"
#include <string.h>
#include <ctype.h>
#include "PRUserDefaults.h"
#include <sys/file.h>
#import "PRUpdate060Operation.h"
#import "PRStatement.h"
#import "sqlite_str.h"


// ========================================
// Constants
// ========================================

NSString * const PRFilePboardType = @"PRFilePboardType";
NSString * const PRIndexesPboardType = @"PRIndexesPboardType";

NSString * const PRColInteger = @"PRColInteger";
NSString * const PRColFloat = @"PRColFloat";
NSString * const PRColString = @"PRColString";
NSString * const PRColData = @"PRColData";


@implementation PRDb

// ========================================
// Properties
// ========================================

@dynamic sqlDb;
@synthesize history;
@synthesize library;
@synthesize playlists;
@synthesize queue;
@synthesize libraryViewSource;
@synthesize nowPlayingViewSource;
@synthesize albumArtController;
@synthesize playbackOrder;

- (sqlite3 *)sqlDb
{
    return sqlDb;
}

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    
    history = [[PRHistory alloc] initWithDb:self];
    library = [[PRLibrary alloc] initWithDb:self];
    playlists = [[PRPlaylists alloc] initWithDb:self];
    queue = [[PRQueue alloc] initWithDb:self];
    libraryViewSource = [[PRLibraryViewSource alloc] initWithDb:self];
    nowPlayingViewSource = [[PRNowPlayingViewSource alloc] initWithDb:self];
    playbackOrder = [[PRPlaybackOrder alloc] initWithDb:self];
    albumArtController = [[PRAlbumArtController alloc] initWithDb:self];
    transaction = 0;
    
    NSString *libraryPath = [[PRUserDefaults userDefaults] libraryPath];
    int e = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:libraryPath isDirectory:nil];
    if (!e) {goto create;}
    
    e = [self open];
    if (!e) {goto create;}

    e = [self update];
    if (!e) {goto create;}

    e = [self initialize];
    if (!e) {goto create;}

	return self;
create:;
    NSLog(@"create");
    
    NSError *err;
    e = [self move:&err];
    if (err && e) {
        [[PRLog sharedLog] presentError:err];
    } else if (err && !e) {
        [[PRLog sharedLog] presentFatalError:err];
    }
    
    e = [self open];
    if (!e) {
        [[PRLog sharedLog] presentFatalError:[self databaseCouldNotBeInitializedError]];
    }
    
    [self create];
    
    e = [self initialize];
    if (!e) {
        [[PRLog sharedLog] presentFatalError:[self databaseCouldNotBeInitializedError]];
    }
    return self;
}

- (void)dealloc
{
    [history release];
    [library release];
    [playlists release];
    [libraryViewSource release];
    [nowPlayingViewSource release];
    [albumArtController release];
    [playbackOrder release];
    [super dealloc];
}

- (BOOL)open
{
	int e = sqlite3_initialize();
	if (e != SQLITE_OK) {
		return FALSE;
	}
    sqlite3_close(sqlDb);
    
    NSString *libraryPath = [[PRUserDefaults userDefaults] libraryPath];
	e = sqlite3_open_v2([libraryPath fileSystemRepresentation], &sqlDb, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL);
	if (e != SQLITE_OK) {return FALSE;}
    
	e = sqlite3_extended_result_codes(sqlDb, TRUE);
	if (e != SQLITE_OK) {return FALSE;}
    
	e = sqlite3_exec(sqlDb, "PRAGMA foreign_keys = ON", NULL, NULL, NULL);
	if (e != SQLITE_OK) {return FALSE;}
    
	e = sqlite3_create_collation(sqlDb, "NOCASE2", SQLITE_UTF16, NULL, no_case);
	if (e != SQLITE_OK) {return FALSE;}
    
    e = sqlite3_create_function_v2(sqlDb, "hfs_begins", 2, SQLITE_UTF16, NULL, hfs_begins, NULL, NULL, NULL);
    if (e != SQLITE_OK) {return FALSE;}
    
    e = sqlite3_create_collation(sqlDb, "hfs_compare", SQLITE_UTF16, NULL, hfs_compare);
	if (e != SQLITE_OK) {return FALSE;}
    
    return TRUE;
}

- (BOOL)initialize
{
    int e = [history initialize];
    if (!e) {return FALSE;}
    
    e = [library initialize];
    if (!e) {return FALSE;}
    NSLog(@"e");
    e = [playlists initialize];
    if (!e) {return FALSE;}
    NSLog(@"2");
    e = [queue initialize];
    if (!e) {return FALSE;}
    NSLog(@"3");
    e = [libraryViewSource initialize];
    if (!e) {return FALSE;}
    NSLog(@"4");
    e = [nowPlayingViewSource initialize];
    if (!e) {return FALSE;}
    NSLog(@"5");
    return TRUE;
}

- (BOOL)update
{
    NSString *string = @"SELECT version FROM schema_version";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [self attempt:string bindings:nil columns:columns];
    if (!result || [result count] != 1) {
        return FALSE;
    }
    NSArray *e;
    int version = [[[result objectAtIndex:0] objectAtIndex:0] intValue];
    if (version == 1) {
        [self begin];
        string = @"DROP TABLE IF EXISTS now_playing_view_source";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"DROP TABLE IF EXISTS playback_order";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"ALTER TABLE library ADD COLUMN lastModified TEXT NOT NULL DEFAULT '' ";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"CREATE INDEX IF NOT EXISTS index_path ON library (path COLLATE NOCASE)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"DELETE FROM library WHERE file_id NOT IN ("
        "SELECT min(file_id) FROM library GROUP BY path COLLATE NOCASE)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"DROP TABLE IF EXISTS history";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"CREATE TABLE IF NOT EXISTS history ("
        "file_id INTEGER NOT NULL, "
        "date TEXT NOT NULL, "
        "FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"CREATE TABLE IF NOT EXISTS queue ("
        "queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
        "playlist_item_id INTEGER NOT NULL UNIQUE, "
        "FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"UPDATE schema_version SET version = 2";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        [self commit];
        version = 2;
    }
    if (version == 2) {
        [self begin];
        string = @"CREATE TABLE playback_order ("
        "index_ INTEGER PRIMARY KEY, "
        "playlist_item_id INTEGER NOT NULL, "
        "CHECK (index_ > 0), "
        "FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE RESTRICT ON DELETE CASCADE)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"UPDATE schema_version SET version = 3";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        [self commit];
        version = 3;
    }
    if (version == 3) {
        [self begin];
        string = @"UPDATE playlists SET browserInfo = x'', listViewSortColumn = -2, albumListViewSortColumn = -2 WHERE type = 1 OR type = 2 OR type = 3";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"UPDATE schema_version SET version = 4";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        [self commit];
        version = 4;
    }
    if (version == 4) {
        [self begin];
        string = @"DROP INDEX IF EXISTS index_path";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"CREATE INDEX index_path ON library (path COLLATE hfs_compare)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"UPDATE schema_version SET version = 5";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        [self commit];
        version = 5;
    }
    if (version == 5) {
        [self begin];
        string = @"ALTER TABLE library ADD COLUMN lyrics TEXT NOT NULL DEFAULT '' ";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"ALTER TABLE library ADD COLUMN compilation INT NOT NULL DEFAULT 0 ";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"CREATE INDEX index_compilation ON library (compilation)";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        string = @"UPDATE schema_version SET version = 6";
        e = [self attempt:string];
        if (!e) {return FALSE;}
        
        [[_core opQueue] addOperation:[PRUpdate060Operation operationWithCore:_core]];
        
        [self commit];
        version = 6;
    }
    return TRUE;
}

- (void)create
{
    NSString *string = @"CREATE TABLE schema_version (version INTEGER NOT NULL)";
    [self execute:string];
    string = @"INSERT INTO schema_version (version) VALUES (6)";
    [self execute:string];
    
    [history create];
    [library create];
    [playlists create];
    [queue create];
    [libraryViewSource create];
    [nowPlayingViewSource create];
    [playbackOrder create];
}

- (BOOL)move:(NSError **)err
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    BOOL libraryExists = [fileManager fileExistsAtPath:[[PRUserDefaults userDefaults] libraryPath]];
    BOOL artExists = [fileManager fileExistsAtPath:[[PRUserDefaults userDefaults] cachedAlbumArtPath]];
    if (!libraryExists && !artExists) {
        *err = nil;
        return TRUE;
    }
    
    NSString *folder;
    int i = 1;
    while (TRUE) {
        NSString *folderName;
        NSString *date = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
        if (i == 1) {
            folderName = [NSString stringWithFormat:@"Backup %@", date];
        } else {
            folderName = [NSString stringWithFormat:@"Backup %@ %d", date, i];
        }
        folder = [[[PRUserDefaults userDefaults] backupPath] stringByAppendingPathComponent:folderName];
        if (![fileManager fileExistsAtPath:folder isDirectory:nil]) {
            break;
        }
        
        i++;
        if (i >= 50) {
            *err = [self databaseCouldNotBeMovedError];
            return FALSE;
        }
    }
    
    int e = [fileManager createDirectoryAtPath:folder 
                     withIntermediateDirectories:TRUE 
                                      attributes:nil 
                                           error:nil];
    if (!e) {
        *err = [self databaseCouldNotBeMovedError];
        return FALSE;
    }
    
    NSString *library_ = [[PRUserDefaults userDefaults] libraryPath];
    NSString *newLibrary = [folder stringByAppendingPathComponent:@"Enqueue.db"];
    e = [fileManager moveItemAtPath:library_ toPath:newLibrary error:nil];
    if (!e) {
        *err = [self databaseCouldNotBeMovedError];
        return FALSE;
    }
    
    NSString *art = [[PRUserDefaults userDefaults] cachedAlbumArtPath];
    NSString *newArt = [folder stringByAppendingPathComponent:@"Cached Album Art"];
    e = [fileManager moveItemAtPath:art toPath:newArt error:nil];
    if (!e) {
        *err = [self databaseCouldNotBeMovedError];
        return FALSE;
    }
    
    *err = [self databaseWasMovedError:folder];
    return TRUE;
}

// ========================================
// Action
// ========================================

- (void)begin
{
    if (transaction == 0) {
        [self execute:@"BEGIN EXCLUSIVE"];
    }
    transaction += 1;
}

- (void)rollback
{
    [self execute:@"ROLLBACK"];
}

- (void)commit
{
    if (transaction < 1) {
        [PRException raise:NSInternalInconsistencyException format:@"Commit index > 1"];
    } else if (transaction == 1) {
        [self execute:@"COMMIT"];
        transaction = 0;
    } else {
        transaction -= 1;
    }
}

- (NSArray *)execute:(NSString *)string
{
    return [[PRStatement statement:string bindings:nil columns:nil db:self] execute];
}

- (NSArray *)execute:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns
{
    return [[PRStatement statement:string bindings:bindings columns:columns db:self] execute];
}

- (NSArray *)attempt:(NSString *)string
{
    return [[PRStatement statement:string bindings:nil columns:nil db:self] attempt];
}

- (NSArray *)attempt:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns
{
    return [[PRStatement statement:string bindings:bindings columns:columns db:self] attempt];
}

- (long)lastInsertRowid
{
    return sqlite3_last_insert_rowid(sqlDb);
}

// ========================================
// Error
// ========================================

- (NSError *)databaseWasMovedError:(NSString *)newPath
{
    NSString *description = @"The Enqueue library file does not appear to be valid.";
    NSString *recovery = [NSString stringWithFormat:@"A new library has been created and the previous library has been moved to:%@", newPath];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

- (NSError *)databaseCouldNotBeMovedError
{
    NSString *description = @"The Enqueue database does not appear to be valid.";
    NSString *recovery = @"Enqueue could not move the existing database and must close. "
    "If this problem persists please contact support.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

- (NSError *)databaseCouldNotBeInitializedError
{
    NSString *description = @"Enqueue could not initialize the database and must close.";
    NSString *recovery = @"If this problem persists please contact support.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

@end


