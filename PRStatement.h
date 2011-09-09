#import <Foundation/Foundation.h>

@class PRDb;

// ========================================
// PRStatement
// ========================================
@interface PRStatement : NSObject 
{
    NSString *_statement;
    NSDictionary *_bindings;
    NSArray *_columns;
    
    sqlite3 *_sqlite3;
    sqlite3_stmt *_stmt;
}

- (id)initWithString:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db;
+ (PRStatement *)statement:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db;

- (NSArray *)execute;
- (NSArray *)attempt;

- (NSArray *)execute_:(BOOL)crash;

@end