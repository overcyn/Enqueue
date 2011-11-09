#import "sqlite3.h"
#import "PRStatement.h"
#import "PRDb.h"

@implementation PRStatement

- (NSString *)description
{
    return [NSString stringWithFormat:@"statement:%@ bindings:%@ columns:%@", _statement, _bindings, _columns];
}

// ========================================
// Initialization
// ========================================

- (id)initWithString:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db
{
    if (!(self = [super init])) {return nil;}
    _statement = [string copy];
    _bindings = [bindings copy];
    _columns = [columns copy];
    _sqlite3 = [db sqlDb];
    
    if (!_bindings) {
        _bindings = [[NSDictionary dictionary] retain];
    }
    if (_columns == nil) {
        _columns = [[NSArray array] retain];
    }
    
    // Prepare statement
    BOOL l = TRUE;
    while (l) {
        int e = sqlite3_prepare_v2(_sqlite3, [_statement UTF8String], -1, &_stmt, NULL);
        switch (e) {
            case SQLITE_OK:
                l = FALSE;
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
    
    // Bind values
    for (NSNumber *key in [_bindings allKeys]) {
        BOOL l = TRUE;
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
                    l = FALSE;
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
    return self;
}

+ (PRStatement *)statement:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db
{
    return [[[PRStatement alloc] initWithString:string bindings:bindings columns:columns db:db] autorelease];
}

- (void)dealloc
{
    sqlite3_finalize(_stmt);
    [_bindings release];
    [_statement release];
    [_columns release];
    [super dealloc];
}

// ========================================
// Action
// ========================================

- (NSArray *)execute
{
    return [self execute_:TRUE];
}

- (NSArray *)attempt
{
    return [self execute_:FALSE];
}

- (NSArray *)execute_:(BOOL)crash
{
//    if (![NSThread isMainThread]) {
//        [PRException raise:PRDbInconsistencyException format:@"Not on main thread!", self];
//        return nil;
//    }
    
    NSMutableArray *result = [NSMutableArray array];
    BOOL l = TRUE;
    while (l) {
        int e = sqlite3_step(_stmt);
        switch (e) {
            case SQLITE_ROW:
                if (sqlite3_column_count(_stmt) != [_columns count]) {
                    if (!crash) {return nil;}
                    [PRException raise:PRDbInconsistencyException format:@"Mismatch column count - self:%@", self];
                }
                NSMutableArray *column = [NSMutableArray array];
                for (int i = 0; i < [_columns count]; i++) {
                    id value;
                    switch ([[_columns objectAtIndex:i] intValue]) {
                        case PRColumnInteger:
                            value = [NSNumber numberWithLongLong:sqlite3_column_int64(_stmt, i)];
                            break;
                        case PRColumnFloat:
                            value = [NSNumber numberWithDouble:sqlite3_column_double(_stmt, i)];
                            break;
                        case PRColumnString:
                            value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(_stmt, i)];
                            break;
                        case PRColumnData:
                            value = [NSData dataWithBytes:sqlite3_column_blob(_stmt, i) length:sqlite3_column_bytes(_stmt, i)];
                            break;
                        default:
                            if (!crash) {return nil;}
                            [PRException raise:PRDbInconsistencyException 
                                        format:@"Unknown column type - self:%@", self];return nil;
                            break;
                    }
                    [column addObject:value];
                }
                [result addObject:column];
                break;
            case SQLITE_BUSY:
                usleep(50);
                break;
            case SQLITE_LOCKED:
                usleep(50);
                sqlite3_reset(_stmt);
                break;
            case SQLITE_DONE:
                l = FALSE;
                break;
            default:
                if (!crash) {return nil;}
                [PRException raise:PRDbInconsistencyException 
                            format:@"Step Failed - self:%@ code:%d msg:%s", self, e, sqlite3_errmsg(_sqlite3)];
                break;
        }
    }
    return result;
}

@end
