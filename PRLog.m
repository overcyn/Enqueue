#import "PRLog.h"
#import <Cocoa/Cocoa.h>

NSString * const PREnqueueErrorDomain = @"PREnqueueErrorDomain";
NSString * const PRSQLiteErrorDomain = @"PRSQLiteErrorDomain";


@implementation PRLog

#pragma mark - Initialization

+ (PRLog *)sharedLog {
    return [[PRLog alloc] init];
}

#pragma mark - Action

- (void)presentError:(NSError *)error {
    [self performSelectorOnMainThread:@selector(presentError_:) withObject:error waitUntilDone:YES];
}

- (void)presentError_:(NSError *)error {
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

- (void)presentFatalError:(NSError *)error {
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"Close Enqueue"];
    
    NSButton *closeButton = [[alert buttons] objectAtIndex:0];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(close)];
    [alert runModal];
}

- (void)presentFatalError_:(NSError *)error {
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"Close Enqueue"];
    
    NSButton *closeButton = [[alert buttons] objectAtIndex:0];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(close)];
    [alert runModal];
    
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    for (NSString *mode in (__bridge NSArray *)allModes) {
        CFRunLoopRunInMode((__bridge CFStringRef)mode, 0.001, false);
    }
    CFRelease(allModes);
}

- (void)close {
    [NSApp terminate:nil];
    exit(EXIT_FAILURE);
}

@end
