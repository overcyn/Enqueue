#import <Foundation/Foundation.h>

extern NSString * const PRSQLiteErrorDomain;
extern NSString * const PREnqueueErrorDomain;
enum {
    PRLibraryInternalErrorCode,
    PRLibraryPermissionsErrorCode,
    PRLibraryCorruptErrorCode,
    PRLibraryIOErrorCode,
    PRLibraryDiskFullErrorCode,
};

@class PRMainWindowController;

@interface PRLog : NSObject 
{
    NSString *backtrace_;
    BOOL dismissed;
    BOOL fatalError;
    PRMainWindowController *mainWindowController;
    NSMenu *mainMenu;
}

// ========================================
// Initialization

+ (PRLog *)sharedLog;

// ========================================
// Action

- (void)presentError:(NSError *)error;
- (void)presentFatalError:(NSError *)error;

@end
