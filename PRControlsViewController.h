#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRNowPlayingController, PRGradientView, PRLibraryViewController, PRCore,
PRTimeFormatter;

@interface PRControlsViewController : NSViewController 
{	
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSSlider *controlSlider;
	IBOutlet NSButton *playPause;
	IBOutlet NSButton *next;
	IBOutlet NSButton *previous;
	IBOutlet NSButton *shuffle;
	IBOutlet NSButton *repeat;	
	
    IBOutlet NSButton *titleButton;
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *albumField;
	IBOutlet NSTextField *artistField;
	IBOutlet NSSegmentedControl *ratingControl;
	IBOutlet NSTextField *currentTime;
	IBOutlet NSTextField *duration;
	
	IBOutlet NSImageView *albumArtView;
	IBOutlet NSImageView *icon;
    
    IBOutlet PRGradientView *gradientView;
    
    PRTimeFormatter *timeFormatter;
    BOOL mouseInTitle;
        
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
// Update

- (void)update;

// For some reason |PRMoviePlayer isPlaying| is slow to update. Probably has to do with threading. 
// So we update the playbutton with the currentTime and we do it seperately from the rest of the UI
// to not bog everything down.
- (void)updatePlayButton;

// ========================================
// Action

- (void)showInLibrary;
- (void)setShowsArtwork:(BOOL)showsArtwork;
- (void)setMiniPlayer:(BOOL)miniPlayer;

@end