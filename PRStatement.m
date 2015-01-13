#import "sqlite3.h"
#import "PRStatement.h"
#import "PRDb.h"
#import "PRConnection.h"
#import "PRException.h"

@implementation PRStatement {
    NSString *_statement;
    NSDictionary *_bindings;
    NSArray *_columns;
    
    sqlite3 *_sqlite3;
    sqlite3_stmt *_stmt;
}

#pragma mark - Initialization

- (id)initWithString:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns connection:(PRConnection *)connection {
    if (!(self = [super init])) {return nil;}
    _sqlite3 = [connection sqliteDb];
    _statement = string;
    if (!columns) {
        _columns = [[NSArray alloc] init];
    } else {
        _columns = columns;
    }
    
    // Prepare statement
    BOOL l = YES;
    while (l) {
        int e = sqlite3_prepare_v2(_sqlite3, [_statement UTF8String], -1, &_stmt, NULL);
        switch (e) {
            case SQLITE_OK:
                l = NO;
                break;
            case SQLITE_BUSY:
            case SQLITE_LOCKED:
                usleep(50);
            default:
                [PRException raise:PRDbInconsistencyException 
                            format:@"Prep Failed - self:%@ code:%d msg:%s", self, e, sqlite3_errmsg(_sqlite3)];
                break;
        }
    }
    // Set Bindings
    [self setBindings:bindings];
    return self;
}

- (id)initWithString:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _sqlite3 = [db sqlDb];
    _statement = string;
    if (!columns) {
        _columns = [[NSArray alloc] init];
    } else {
        _columns = columns;
    }
    
    // Prepare statement
    BOOL l = YES;
    while (l) {
        int e = sqlite3_prepare_v2(_sqlite3, [_statement UTF8String], -1, &_stmt, NULL);
        switch (e) {
            case SQLITE_OK:
                l = NO;
                break;
            case SQLITE_BUSY:
            case SQLITE_LOCKED:
                usleep(50);
            default:
                [PRException raise:PRDbInconsistencyException 
                            format:@"Prep Failed - self:%@ code:%d msg:%s", self, e, sqlite3_errmsg(_sqlite3)];
                break;
        }
    }
    // Set Bindings
    [self setBindings:bindings];
    return self;
}

- (void)dealloc {
    sqlite3_finalize(_stmt);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"statement:%@ bindings:%@ columns:%@", _statement, _bindings, _columns];
}

#pragma mark - Accessors

@synthesize statement = _statement, bindings = _bindings, columns = _columns;

- (void)setBindings:(NSDictionary *)bindings {
    if (!bindings) {
        bindings = [[NSDictionary alloc] init];
    } else {
        bindings = bindings;
    }
    _bindings = bindings;
    
    sqlite3_reset(_stmt);
    
    for (NSNumber *key in [_bindings allKeys]) {
        BOOL l = YES;
        while (l) {
            id object = [_bindings objectForKey:key];
            int e;
            if ([object isKindOfClass:[NSNumber class]]) {
                if ([object objCType][0] == 'f' || [object objCType][0] == 'd') { // if float or double
                    e = sqlite3_bind_double(_stmt, [key intValue], [object doubleValue]);
                } else { // if int
                    e = sqlite3_bind_int64(_stmt, [key intValue], [object longLongValue]);
                }
            } else if ([object isKindOfClass:[NSString class]]) {
                e = sqlite3_bind_text(_stmt, [key intValue], [object UTF8String], -1, SQLITE_TRANSIENT);
            } else if ([object isKindOfClass:[NSData class]]) {
                e = sqlite3_bind_blob(_stmt, [key intValue], [object bytes], [object length], SQLITE_TRANSIENT);
            } else {
                [PRException raise:PRDbInconsistencyException 
                            format:@"Unknown binding type - self:%@", self];
            }
            
            switch (e) {
                case SQLITE_OK:
                    l = NO;
                    break;
                case SQLITE_LOCKED:
                case SQLITE_BUSY:
                    usleep(50);
                    break;
                default:;
                    [PRException raise:PRDbInconsistencyException 
                                format:@"Bind failed - self:%@ code:%d msg:%s", self, e, sqlite3_errmsg(_sqlite3)];
                    break;
            }
        }
    }
}

#pragma mark - Action

- (NSArray *)execute {
    NSArray *outValue = nil;
    if (![self _execute:&outValue]) {
        [PRException raise:PRDbInconsistencyException format:nil];
    }
    return outValue;
}

- (NSArray *)attempt {
    NSArray *outValue = nil;
    [self _execute:&outValue];
    return outValue;
}

- (BOOL)zExecute:(NSArray **)outValue {
    BOOL success = [self _execute:outValue];
    if (!success) {
        @throw NSInternalInconsistencyException;
    }
    return success;
}

#pragma mark - action

- (BOOL)_execute:(NSArray **)outValue {
    NSMutableArray *result = [NSMutableArray array];
    BOOL l = YES;
    while (l) {
        int e = sqlite3_step(_stmt);
        switch (e) {
            case SQLITE_ROW: {
                if (sqlite3_column_count(_stmt) != [_columns count]) {
                    return NO;
                }
                NSMutableArray *column = [[NSMutableArray alloc] init];
                for (int i = 0; i < [_columns count]; i++) {
                    id value;
                    id col = [_columns objectAtIndex:i];
                    if (col == PRColInteger) {
                        value = [[NSNumber alloc] initWithLongLong:sqlite3_column_int64(_stmt, i)];
                    } else if (col == PRColInteger) {
                        value = [[NSNumber alloc] initWithDouble:sqlite3_column_double(_stmt, i)];
                    } else if (col == PRColString) {
                        value = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(_stmt, i)];
                    } else if (col == PRColData) {
                        value = [[NSData alloc] initWithBytes:sqlite3_column_blob(_stmt, i) length:sqlite3_column_bytes(_stmt, i)];
                    } else {
                        return NO;
                    }
                    [column addObject:value];
                }
                [result addObject:column];
                break;
            }
            case SQLITE_BUSY:
                usleep(50);
                break;
            case SQLITE_LOCKED:
                usleep(50);
                sqlite3_reset(_stmt);
                break;
            case SQLITE_DONE:
                l = NO;
                break;
            default:
                return NO;
        }
    }
    
    if (outValue) {
        *outValue = result;
    }
    return YES;
}

@end
