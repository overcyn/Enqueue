#import <AppKit/AppKit.h>
#import "PRRule.h"

@interface PRRuleCompound : PRRule
{
    NSMutableArray *_subRules;
}

@property (readonly, assign) NSMutableArray *subRules;

@end
