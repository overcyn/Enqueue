#import <Cocoa/Cocoa.h>

@interface PRControlsView : NSView
@property (nonatomic, readonly) NSButton *playButton;
@property (nonatomic, readonly) NSButton *nextButton;
@property (nonatomic, readonly) NSButton *previousButton;
@property (nonatomic, readonly) NSButton *shuffleButton;
@property (nonatomic, readonly) NSButton *repeatButton;
@property (nonatomic, readonly) NSSlider *volumeSlider;
@property (nonatomic, readonly) NSSlider *progressSlider;
@property (nonatomic, strong) NSString *titleString;
@end
