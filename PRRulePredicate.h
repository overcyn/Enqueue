#import "PRRule.h"

@interface PRRulePredicate : PRRule
{
    NSMutableArray *_values;
    PRFileAttribute _fileAttribute;
}

@property (readwrite) PRFileAttribute fileAttribute;
@property (readwrite, assign) NSMutableArray *values;

- (void)add;

+ (NSString *)predicate;

@end
