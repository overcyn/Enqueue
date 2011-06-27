#import <Cocoa/Cocoa.h>


@interface NSInvocation (Extensions)

+ (id)invocationWithTarget:(id)target
             invocationOut:(NSInvocation **)invocationOut;
+ (id)retainedInvocationWithTarget:(id)target
                     invocationOut:(NSInvocation **)invocationOut;

@end
