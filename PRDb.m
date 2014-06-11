#import "PRCore.h"
#import "PRAlbumArtController.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRLibraryViewSource.h"
#import "PRNowPlayingViewSource.h"
#import "PRPlaybackOrder.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRStatement.h"
#import "PRUpdate060Operation.h"
#import "sqlite_str.h"
#include <ctype.h>
#include <string.h>
#include <sys/file.h>


NSString * const PRFilePboardType = @"PRFilePboardType";
NSString * const PRIndexesPboardType = @"PRIndexesPboardType";

NSString * const PRColFloat = @"PRColFloat";
NSString * const PRColInteger = @"PRColInteger";
NSString * const PRColString = @"PRColString";
NSString * const PRColData = @"PRColData";


@implementation PRDb {
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

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
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
    _cachedStatements = [[NSMutableDictionary alloc] init];
    transaction = 0;

    BOOL e = ([[[NSFileManager alloc] init] fileExistsAtPath:[[PRDefaults sharedDefaults] libraryPath] isDirectory:nil] &&
              [self open] && [self update] && [self initialize]);
    if (!e) {
        NSLog(@"create");
        NSError *err;
        int e = [self move:&err];
        if (err && e) {
            [[PRLog sharedLog] presentError:err];
        } else if (err && !e) {
            [[PRLog sharedLog] presentFatalError:err];
        }
        if (![self open]) {
            [[PRLog sharedLog] presentFatalError:[self databaseCouldNotBeInitializedError]];
        }
        [self create];
        if (![self initialize]) {
            [[PRLog sharedLog] presentFatalError:[self databaseCouldNotBeInitializedError]];
        }
    }
    return self;
}


#pragma mark - Initialization Priv

- (BOOL)open {
    if (sqlite3_initialize() != SQLITE_OK) {
        return NO;
    }
    sqlite3_close(sqlDb);

    return (SQLITE_OK == sqlite3_open_v2([[[PRDefaults sharedDefaults] libraryPath] fileSystemRepresentation], &sqlDb,
                                         SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) &&
            SQLITE_OK == sqlite3_extended_result_codes(sqlDb, YES) &&
            SQLITE_OK == sqlite3_exec(sqlDb, "PRAGMA foreign_keys = ON", NULL, NULL, NULL) &&
            SQLITE_OK == sqlite3_create_collation(sqlDb, "NOCASE2", SQLITE_UTF16, NULL, no_case) &&
            SQLITE_OK == sqlite3_create_function_v2(sqlDb, "hfs_begins", 2, SQLITE_UTF16, NULL, hfs_begins, NULL, NULL, NULL) &&
            SQLITE_OK == sqlite3_create_collation(sqlDb, "hfs_compare", SQLITE_UTF16, NULL, hfs_compare));
}

- (BOOL)initialize {
    return (
        [history initialize] &&
        [library initialize] &&
        [playlists initialize] &&
        [queue initialize] &&
        [libraryViewSource initialize] &&
        [nowPlayingViewSource initialize]);
}

- (BOOL)update {
    NSArray *result = [self attempt:@"SELECT version FROM schema_version" bindings:nil columns:@[PRColInteger]];
    if (!result || [result count] != 1) {
        return NO;
    }
    int version = [[[result objectAtIndex:0] objectAtIndex:0] intValue];
    if (version == 1) {
        [self begin];
        BOOL e = ([self attempt:@"DROP TABLE IF EXISTS now_playing_view_source"] &&
                  [self attempt:@"DROP TABLE IF EXISTS playback_order"] &&
                  [self attempt:@"ALTER TABLE library ADD COLUMN lastModified TEXT NOT NULL DEFAULT '' "] &&
                  [self attempt:@"CREATE INDEX IF NOT EXISTS index_path ON library (path COLLATE NOCASE)"] &&
                  [self attempt:@"DELETE FROM library WHERE file_id NOT IN (SELECT min(file_id) FROM library GROUP BY path COLLATE NOCASE)"] &&
                  [self attempt:@"DROP TABLE IF EXISTS history"] &&
                  [self attempt:@"CREATE TABLE IF NOT EXISTS history ("
                   "file_id INTEGER NOT NULL, "
                   "date TEXT NOT NULL, "
                   "FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE)"] &&
                  [self attempt:@"CREATE TABLE IF NOT EXISTS queue ("
                   "queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
                   "playlist_item_id INTEGER NOT NULL UNIQUE, "
                   "FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)"] &&
                  [self attempt:@"UPDATE schema_version SET version = 2"]);
        [self commit];
        if (!e) {
            return NO;
        }
        version = 2;
    }
    if (version == 2) {
        [self begin];
        BOOL e = ([self attempt:@"CREATE TABLE playback_order ("
                   "index_ INTEGER PRIMARY KEY, "
                   "playlist_item_id INTEGER NOT NULL, "
                   "CHECK (index_ > 0), "
                   "FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE RESTRICT ON DELETE CASCADE)"] &&
                  [self attempt:@"UPDATE schema_version SET version = 3"]);
        [self commit];
        if (!e) {
            return NO;
        }
        version = 3;
    }
    if (version == 3) {
        [self begin];
        BOOL e = ([self attempt:@"UPDATE playlists SET browserInfo = x'', listViewSortColumn = -2, "
                   "albumListViewSortColumn = -2 WHERE type = 1 OR type = 2 OR type = 3"] &&
                  [self attempt:@"UPDATE schema_version SET version = 4"]);
        [self commit];
        if (!e) {
            return NO;
        }
        version = 4;
    }
    if (version == 4) {
        [self begin];
        BOOL e = ([self attempt:@"DROP INDEX IF EXISTS index_path"] &&
                  [self attempt:@"CREATE INDEX index_path ON library (path COLLATE hfs_compare)"] &&
                  [self attempt:@"UPDATE schema_version SET version = 5"]);
        [self commit];
        if (!e) {
            return NO;
        }
        version = 5;
    }
    if (version == 5) {
        [self begin];
        BOOL e = ([self attempt:@"ALTER TABLE library ADD COLUMN lyrics TEXT NOT NULL DEFAULT '' "] &&
                  [self attempt:@"ALTER TABLE library ADD COLUMN compilation INT NOT NULL DEFAULT 0 "] &&
                  [self attempt:@"CREATE INDEX index_compilation ON library (compilation)"] &&
                  [self attempt:@"UPDATE schema_version SET version = 6"]);
        [[_core opQueue] addOperation:[PRUpdate060Operation operationWithCore:_core]];
        [self commit];
        if (!e) {
            return NO;
        }
//        version = 6;
    }
//    
//    if (version == 6) {
//        [self begin];
//        e = [self attempt:@"REINDEX NOCASE2"];
//        if (!e) {return NO;}
//        
//        e = [self attempt:@"ALTER TABLE library ADD COLUMN resolvedYear INT NOT NULL DEFAULT 0 "];
//        if (!e) {return NO;}
//        [self commit];
//        version = 7;
//    }
     
    return YES;
}

- (void)create {
    [self execute:@"CREATE TABLE schema_version (version INTEGER NOT NULL)"];
    [self execute:@"INSERT INTO schema_version (version) VALUES (6)"];
    
    [history create];
    [library create];
    [playlists create];
    [queue create];
    [libraryViewSource create];
    [nowPlayingViewSource create];
    [playbackOrder create];
}

- (BOOL)move:(NSError **)err {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL libraryExists = [fileManager fileExistsAtPath:[[PRDefaults sharedDefaults] libraryPath]];
    BOOL artExists = [fileManager fileExistsAtPath:[[PRDefaults sharedDefaults] cachedAlbumArtPath]];
    if (!libraryExists && !artExists && err) {
        *err = nil;
        return YES;
    }
    
    NSString *folder;
    int i = 1;
    while (YES) {
        NSString *folderName;
        NSString *date = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
        if (i == 1) {
            folderName = [NSString stringWithFormat:@"Backup %@", date];
        } else {
            folderName = [NSString stringWithFormat:@"Backup %@ %d", date, i];
        }
        folder = [[[PRDefaults sharedDefaults] backupPath] stringByAppendingPathComponent:folderName];
        if (![fileManager fileExistsAtPath:folder isDirectory:nil]) {
            break;
        }
        
        i++;
        if (i >= 50) {
            *err = [self databaseCouldNotBeMovedError];
            return NO;
        }
    }
    
    int e = [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    if (!e && err) {
        *err = [self databaseCouldNotBeMovedError];
        return NO;
    }
    
    NSString *library_ = [[PRDefaults sharedDefaults] libraryPath];
    NSString *newLibrary = [folder stringByAppendingPathComponent:@"Enqueue.db"];
    e = [fileManager moveItemAtPath:library_ toPath:newLibrary error:nil];
    if (!e && err) {
        *err = [self databaseCouldNotBeMovedError];
        return NO;
    }
    
    NSString *art = [[PRDefaults sharedDefaults] cachedAlbumArtPath];
    NSString *newArt = [folder stringByAppendingPathComponent:@"Cached Album Art"];
    e = [fileManager moveItemAtPath:art toPath:newArt error:nil];
    if (!e && err) {
        *err = [self databaseCouldNotBeMovedError];
        return NO;
    }
    
    if (err) {
        *err = [self databaseWasMovedError:folder];
    }
    return YES;
}

#pragma mark - Accessors

@synthesize sqlDb, history, library, playlists, queue, libraryViewSource, nowPlayingViewSource, albumArtController, playbackOrder;

- (long)lastInsertRowid {
    return sqlite3_last_insert_rowid(sqlDb);
}

#pragma mark - Action

- (void)begin {
    if (transaction == 0) {
        [self executeCached:@"BEGIN EXCLUSIVE"];
    }
    transaction += 1;
}

- (void)rollback {
    [self executeCached:@"ROLLBACK"];
}

- (void)commit {
    if (transaction < 1) {
        [PRException raise:NSInternalInconsistencyException format:@"Commit index > 1"];
    } else if (transaction == 1) {
        [self executeCached:@"COMMIT"];
        transaction = 0;
    } else {
        transaction -= 1;
    }
}

- (NSArray *)execute:(NSString *)string {
    return [self execute:string bindings:nil columns:nil];
}

- (NSArray *)execute:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns {
    PRStatement *stmt = [[PRStatement alloc] initWithString:string bindings:bindings columns:columns db:self];
    id rlt = [stmt execute];
    return rlt;
}

- (NSArray *)executeCached:(NSString *)string {
    return [self executeCached:string bindings:nil columns:nil];
}

- (NSArray *)executeCached:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns {
    PRStatement *statement = [_cachedStatements objectForKey:string];
    if (!statement || ![[statement columns] isEqual:columns]) {
        statement = [PRStatement statement:string bindings:bindings columns:columns db:self];
        [_cachedStatements setObject:statement forKey:string];
    }
    return [statement execute];
}

- (NSArray *)attempt:(NSString *)string {
    return [self attempt:string bindings:nil columns:nil];
}

- (NSArray *)attempt:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns {
    PRStatement *stmt = [[PRStatement alloc] initWithString:string bindings:bindings columns:columns db:self];
    id rlt = [stmt attempt];
    return rlt;
}

- (NSArray *)explain:(NSString *)string {
    return [self explain:string bindings:nil columns:nil];
}

- (NSArray *)explain:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns {
    NSArray *explain = [self execute:[NSString stringWithFormat:@"EXPLAIN %@",string]
                            bindings:bindings
                             columns:@[PRColInteger,PRColInteger,PRColInteger,PRColInteger,PRColInteger,PRColInteger,PRColInteger,PRColInteger]];
    NSDate *date = [NSDate date];
    NSArray *rlt = [self execute:string bindings:bindings columns:columns];
    NSLog(@"time:%f string:%@ explain:%@",[date timeIntervalSinceNow],string, explain);
    return rlt;
}

#pragma mark - Error

- (NSError *)databaseWasMovedError:(NSString *)newPath {
    NSString *description = @"The Enqueue library file does not appear to be valid.";
    NSString *recovery = [NSString stringWithFormat:@"A new library has been created and the previous library has been moved to:%@", newPath];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

- (NSError *)databaseCouldNotBeMovedError {
    NSString *description = @"The Enqueue database does not appear to be valid.";
    NSString *recovery = @"Enqueue could not move the existing database and must close. "
    "If this problem persists please contact support.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

- (NSError *)databaseCouldNotBeInitializedError {
    NSString *description = @"Enqueue could not initialize the database and must close.";
    NSString *recovery = @"If this problem persists please contact support.";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              description, NSLocalizedDescriptionKey,
                              recovery, NSLocalizedRecoverySuggestionErrorKey,
                              nil];
    return [NSError errorWithDomain:PREnqueueErrorDomain code:0 userInfo:userInfo];
}

@end
