#import <Foundation/Foundation.h>

@class PRCore, PRTask;

@interface PRUpdate060Operation : NSOperation
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
