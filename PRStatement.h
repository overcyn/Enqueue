#import <Foundation/Foundation.h>
@class PRDb;


@interface PRStatement : NSObject {
    NSString *_statement;
    NSDictionary *_bindings;
    NSArray *_columns;
    
    sqlite3 *_sqlite3;
    sqlite3_stmt *_stmt;
}
/* Initialization */
- (id)initWithString:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db;
+ (PRStatement *)statement:(NSString *)string bindings:(NSDictionary *)bindings columns:(NSArray *)columns db:(PRDb *)db;

/* Accessors */
@property (readonly) NSString *statement;
@property (nonatomic, strong) NSDictionary *bindings;
@property (readonly) NSArray *columns;

/* Action */
- (NSArray *)execute;
- (NSArray *)attempt;
@end
