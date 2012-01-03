#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRNowPlayingController, PRGradientView, PRLibraryViewController, PRCore,
PRTimeFormatter, PRHeaderBox, PRHyperlinkButton;

@interface PRControlsViewController : NSViewController 
{	
	IBOutlet NSButton *playPause;
	IBOutlet NSButton *next;
	IBOutlet NSButton *previous;
	IBOutlet NSButton *shuffle;
	IBOutlet NSButton *repeat;	
	
    IBOutlet PRHeaderBox *_box;
    IBOutlet PRHyperlinkButton *titleButton;
    IBOutlet NSTextField *_artistAlbumField;
	IBOutlet NSSegmentedControl *ratingControl;
    
    IBOutlet NSSlider *controlSlider;
	IBOutlet NSTextField *currentTime;
	IBOutlet NSTextField *duration;
	
	IBOutlet NSImageView *albumArtView;
	IBOutlet NSImageView *icon;
    
    IBOutlet NSButton *_volumeButton;
    IBOutlet NSSlider *_volumeSlider;
    
    IBOutlet NSView *_containerView;
    IBOutlet PRGradientView *gradientView;
    
    IBOutlet PRGradientView *_progressDivider;
    IBOutlet NSTextField *_progressTextField;
    IBOutlet NSTextField *_progressPercentTextField;
    IBOutlet NSButton *_progressButton;
    
    BOOL _progressHidden;
    
    PRTimeFormatter *timeFormatter;
    
    PRCore *core;
    PRDb *db;
	PRLibrary *lib;
    PRLibraryViewController *libraryViewController;
	PRNowPlayingController *now;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Accessors

- (NSImageView *)albumArtView;

// ========================================
// Update

- (void)updateLayout;
- (void)updateControls;
- (void)updatePlayButton;

- (void)volumeChanged:(NSNotification *)notification;

// ========================================
// Action

- (BOOL)progressHidden;
- (void)setProgressHidden:(BOOL)progressHidden;
- (void)setProgressTitle:(NSString *)progressTitle;
- (void)setProgressPercent:(int)progressPercent;

- (void)showInLibrary;
- (void)mute;

@end