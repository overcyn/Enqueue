#import <Cocoa/Cocoa.h>
@class PRDb, PRNowPlayingController, PRGradientView, PRLibraryViewController, PRCore, PRHeaderBox, PRHyperlinkButton;


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
    IBOutlet NSTextField *_currentTime;
    IBOutlet NSTextField *duration;
    
    IBOutlet NSImageView *__weak albumArtView;
    
    IBOutlet NSButton *_volumeButton;
    IBOutlet NSSlider *_volumeSlider;
    
    IBOutlet NSView *_containerView;
    IBOutlet PRGradientView *gradientView;
    
    IBOutlet PRGradientView *_progressDivider;
    IBOutlet NSTextField *_progressTextField;
    IBOutlet NSTextField *_progressPercentTextField;
    IBOutlet NSButton *_progressButton;
    
    BOOL _progressHidden;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core_;

/* Accessors */
@property (weak, readonly) NSImageView *albumArtView;

/* Update */
- (void)updateLayout;

/* Action */
- (void)showInLibrary;
@end