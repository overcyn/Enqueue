#import "PRLog.h"

NSString * const PREnqueueErrorDomain = @"PREnqueueErrorDomain";
NSString * const PRSQLiteErrorDomain = @"PRSQLiteErrorDomain";

@implementation PRLog

// ========================================
// Initialization
// ========================================

+ (PRLog *)sharedLog
{
    return [[[PRLog alloc] init] autorelease];
}

// ========================================
// Action
// ========================================

- (void)presentError:(NSError *)error
{
    [self performSelectorOnMainThread:@selector(presentError_:) withObject:error waitUntilDone:TRUE];
}

- (void)presentError_:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

- (void)presentFatalError:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"Close Enqueue"];
    
    NSButton *closeButton = [[alert buttons] objectAtIndex:0];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(close)];
    [alert runModal];
}

- (void)presentFatalError_:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"Close Enqueue"];
    
    NSButton *closeButton = [[alert buttons] objectAtIndex:0];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(close)];
    [alert runModal];
    
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    for (NSString *mode in (NSArray *)allModes) {
        CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
    }
    CFRelease(allModes);
}

- (void)close
{
    [NSApp terminate:nil];
    exit(EXIT_FAILURE);
}

@end
