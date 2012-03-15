#import <Cocoa/Cocoa.h>
@class PRDb, PRNowPlayingController, PRGradientView, PRLibraryViewController, PRCore, PRTimeFormatter, PRHeaderBox, PRHyperlinkButton;


@interface PRControlsViewController : NSViewController {
    __weak PRCore *core;
    __weak PRDb *db;
	__weak PRNowPlayingController *now;
    
	IBOutlet NSButton *playPause;
	IBOutlet NSButton *next;
	IBOutlet NSButton *previous;
	IBOutlet NSButton *shuffle;
	IBOutlet NSButton *repeat;	
	
    IBOutlet PRHeaderBox *_box;
    IBOutlet PRHyperlinkButton *titleButton;
    IBOutlet NSTextField *_artistAlbumField;
    
    IBOutlet NSSlider *controlSlider;
	IBOutlet NSTextField *currentTime;
	IBOutlet NSTextField *duration;
	
	IBOutlet NSImageView *albumArtView;
    
    IBOutlet NSButton *_volumeButton;
    IBOutlet NSSlider *_volumeSlider;
    
    IBOutlet NSView *_containerView;
    IBOutlet PRGradientView *gradientView;
    
    IBOutlet PRGradientView *_progressDivider;
    IBOutlet NSTextField *_progressTextField;
    IBOutlet NSTextField *_progressPercentTextField;
    IBOutlet NSButton *_progressButton;
    
    PRTimeFormatter *timeFormatter;
    
    BOOL _progressHidden;
}
// Initialization
- (id)initWithCore:(PRCore *)core_;

// Accessors
- (NSImageView *)albumArtView;

// Update
- (void)updateLayout;
- (void)updateControls;
- (void)updatePlayButton;
- (void)volumeChanged:(NSNotification *)notification;

// Action
- (BOOL)progressHidden;
- (void)setProgressHidden:(BOOL)progressHidden;
- (void)setProgressTitle:(NSString *)progressTitle;
- (void)setProgressPercent:(int)progressPercent;

- (void)showInLibrary;
- (void)mute;
@end