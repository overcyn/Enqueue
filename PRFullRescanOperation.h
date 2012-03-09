#import <Foundation/Foundation.h>

@class PRCore, PRTask;

@interface PRFullRescanOperation : NSOperation
{
    // weak
    PRCore *_core;
}

// ========================================
// Initialization

+ (id)operationWithCore:(PRCore *)core;
- (id)initWithCore:(PRCore *)core;

// ========================================
// Action

- (void)updateFiles:(NSArray *)array;

@end
