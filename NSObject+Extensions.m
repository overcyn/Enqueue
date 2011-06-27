#import "NSObject+Extensions.h"


@implementation NSObject (Extensions)

- (void)performSelectorInBackground:(SEL)selector withObject:(id)p1 object:(id)p2 
{
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (!signature) {
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&p1 atIndex:2];
    [invocation setArgument:&p2 atIndex:3];
    [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
}

@end
