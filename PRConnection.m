#import "PRConnection.h"
#import "sqlite_str.h"
#import "PRStatement.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"


@implementation PRConnection {
    NSMutableDictionary *_statementCache;
    PRConnectionType _type;
    sqlite3 *_sqliteDb;
    PRLibrary *_library;
    PRPlaylists *_playlists;
}

@synthesize type = _type;
@synthesize sqliteDb = _sqliteDb;
@synthesize library = _library;
@synthesize playlists = _playlists;

- (instancetype)initWithPath:(NSString *)path type:(PRConnectionType)type {
    if ((self = [super init])) {
        _type = type;
        if (sqlite3_initialize() != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_open_v2([path fileSystemRepresentation], &_sqliteDb, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_extended_result_codes(_sqliteDb, YES) != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_exec(_sqliteDb, "PRAGMA foreign_keys = ON", NULL, NULL, NULL) != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_create_collation(_sqliteDb, "NOCASE2", SQLITE_UTF16, NULL, no_case) != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_create_function_v2(_sqliteDb, "hfs_begins", 2, SQLITE_UTF16, NULL, hfs_begins, NULL, NULL, NULL) != SQLITE_OK) {
            return nil;
        }
        if (sqlite3_create_collation(_sqliteDb, "hfs_compare", SQLITE_UTF16, NULL, hfs_compare) != SQLITE_OK) {
            return nil;
        }
        
        _library = [[PRLibrary alloc] initWithConnection:self];
        _playlists = [[PRPlaylists alloc] initWithConnection:self];
    }
    return self;
}

- (BOOL)zTransaction:(BOOL(^)(void))block {
    [self zExecuteCached:@"BEGIN EXCLUSIVE"];
    BOOL success = block();
    if (success) {
        [self zExecuteCached:@"COMMIT"];
    } else {
        [self zExecuteCached:@"ROLLBACK"];
    }
    return success;
}

- (BOOL)zExecute:(NSString *)string {
    return [self zExecute:string bindings:nil columns:nil out:nil];
}

- (BOOL)zExecute:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns out:(NSArray **)outValue {
    PRStatement *stmt = [[PRStatement alloc] initWithString:string bindings:bindings columns:columns connection:self];
    return [stmt zExecute:outValue];
}

- (BOOL)zExecuteCached:(NSString *)string {
    return [self zExecuteCached:string bindings:nil columns:nil out:nil];
}

- (BOOL)zExecuteCached:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns out:(NSArray **)outValue {
    PRStatement *stmt = [_statementCache objectForKey:string];
    if (!stmt || ![[stmt columns] isEqual:columns]) {
        stmt = [[PRStatement alloc] initWithString:string bindings:bindings columns:columns connection:self];
        [_statementCache setObject:stmt forKey:string];
    }
    return [stmt zExecute:outValue];
}

- (NSInteger)userVersion {
    NSArray *rlt = nil;
    [self zExecute:@"PRAGMA user_version" bindings:nil columns:@[PRColInteger] out:&rlt];
    return [rlt[0][0] integerValue];
}

- (void)setUserVersion:(NSInteger)value {
    [self zExecute:[NSString stringWithFormat:@"PRAGMA user_version = %ld", (long)value]];
}

@end