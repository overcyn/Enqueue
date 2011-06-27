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
    [backtrace_ release];
    backtrace_ = [[self backtrace] retain];
    [self performSelectorOnMainThread:@selector(presentFatalError_:) withObject:error waitUntilDone:TRUE];
}

- (void)presentFatalError_:(NSError *)error
{
    [backtrace_ release];
    backtrace_ = [NSString stringWithFormat:@"Error: %@\n, Error Info: %@\n, Backtrace:%@\n", error, [error userInfo], backtrace_];
    NSLog(@"%@",backtrace_);
    
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"Close Enqueue"];
    [alert addButtonWithTitle:@"Details"];
    NSButton *detailsButton = [[alert buttons] objectAtIndex:1];
    [detailsButton setTarget:self];
    [detailsButton setAction:@selector(showDetails)];
    NSButton *closeButton = [[alert buttons] objectAtIndex:0];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(close)];
    [alert runModal];
    
    if (fatalError) {
        [NSApp terminate:nil];
        exit(0);
    }
    fatalError = TRUE;
    
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    for (NSString *mode in (NSArray *)allModes) {
        CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
    }
    CFRelease(allModes);
}

- (NSString *)backtrace
{
    NSMutableString *trace = [NSMutableString string];
    void *backtraceFrames[128];
    int frameCount = backtrace(&backtraceFrames[0], 128);
    char **frameStrings = backtrace_symbols(&backtraceFrames[0], frameCount);
    
    if(frameStrings != NULL) {
        for(int x = 4; x < frameCount; x++) {
            if(frameStrings[x] == NULL) { break; }
            [trace appendFormat:@"%s\n", frameStrings[x]];
        }
        free(frameStrings);
    }
    return trace;
}

- (void)showDetails
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Details"];
    [alert setInformativeText:backtrace_];
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
}

- (void)close
{
    [NSApp terminate:nil];
    exit(EXIT_FAILURE);
}

@end
