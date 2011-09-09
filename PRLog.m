#import "PRLog.h"
#import "PRMainWindowController.h"
#import "NSError+Extensions.h"
#include <execinfo.h>

NSString * const PREnqueueErrorDomain = @"PREnqueueErrorDomain";
NSString * const PRSQLiteErrorDomain = @"PRSQLiteErrorDomain";
static PRLog *sharedLog = nil;

@implementation PRLog

// ========================================
// Initialization
// ========================================

+ (PRLog *)sharedLog
{
    if (sharedLog == nil) {
        sharedLog = [[super allocWithZone:NULL] init];
    }
    return sharedLog;
}

- (id)init
{
    self = [super init];
    if (self) {
        fatalError = FALSE;
        backtrace_ = @"";
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedLog] retain];   
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;   
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
