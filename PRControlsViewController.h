#import <Cocoa/Cocoa.h>
@class PRCore;

@interface PRControlsViewController : NSViewController
- (id)initWithCore:(PRCore *)core;
@property (nonatomic, readonly) NSImageView *albumArtView;
- (void)updateLayout;
- (void)showInLibrary;
@end