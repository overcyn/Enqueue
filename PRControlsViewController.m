#import "PRControlsViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRNowPlayingController.h"
#import "PRMoviePlayer.h"
#import "PRRatingCell.h"
#import "PRAlbumArtController.h"
#import "PRGradientView.h"
#import "BWTexturedSlider.h"
#import "PRSliderCell.h"
#import "PRLibraryViewController.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRTimeFormatter.h"
#import "PRUserDefaults.h"
#import "PRHeaderBox.h"
#import "PRHyperlinkButton.h"
#import "PRNowPlayingViewController.h"
#import "PRTableViewController.h"


@implementation PRControlsViewController

// == Initialization =======================================

- (id)initWithCore:(PRCore *)core_; {
    if (!(self = [super initWithNibName:@"PRControlsView" bundle:nil])) {return nil;}
    core = core_;
    db = [core_ db];
    now = [core_ now];
    libraryViewController = [[core_ win] libraryViewController];
	return self;
}

- (void)dealloc {
    [timeFormatter release];
    [super dealloc];
}

- (void)awakeFromNib  {
	// bind time and volume sliders
    [controlSlider setCell:[[[PRSliderCell alloc] init] autorelease]];
	[controlSlider setMinValue:0.0];
	[controlSlider bind:@"maxValue" toObject:now withKeyPath:@"mov.duration" options:nil];
	[controlSlider bind:@"value" toObject:now withKeyPath:@"mov.currentTime" options:nil];
	    
	// bind buttons
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:FALSE] 
                                                        forKey:NSConditionallySetsEnabledBindingOption];
	[playPause bind:@"target" toObject:now withKeyPath:@"playPause" options:options];
	[next bind:@"target" toObject:now withKeyPath:@"playNext" options:options];
	[previous bind:@"target" toObject:now withKeyPath:@"playPrevious" options:options];
    [shuffle bind:@"target" toObject:now withKeyPath:@"toggleShuffle" options:options];
	[repeat bind:@"target" toObject:now withKeyPath:@"toggleRepeat" options:options];
    
    // Volume
    [_volumeSlider setMaxValue:1];
    [_volumeSlider setMinValue:0];
    [_volumeSlider bind:@"value" toObject:now withKeyPath:@"mov.volume" options:nil];
    [_volumeButton setTarget:self];
    [_volumeButton setAction:@selector(mute)];
    [[NSNotificationCenter defaultCenter] observeVolumeChanged:self sel:@selector(volumeChanged:)];
    [self volumeChanged:nil];
    
	// register for observers
    [[NSNotificationCenter defaultCenter] observeFilesChanged:self sel:@selector(updateControls)];
    [[NSNotificationCenter defaultCenter] observeShuffleChanged:self sel:@selector(updateControls)];
    [[NSNotificationCenter defaultCenter] observeRepeatChanged:self sel:@selector(updateControls)];
    [[NSNotificationCenter defaultCenter] observeTimeChanged:self sel:@selector(updatePlayButton)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(updateControls)];
    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(updateControls)];
    
    [titleButton setTarget:self];
    [titleButton setAction:@selector(showInLibrary)];
    
    timeFormatter = [[PRTimeFormatter alloc] init];
    
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:0.75 alpha:1.0], 0.0,
                             [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], 1.0,
                             nil] autorelease];
    [gradientView setVerticalGradient:gradient];
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:0.96 alpha:1.0], 0.0,
                 [NSColor colorWithCalibratedWhite:0.75 alpha:1.0], 1.0,
                 nil] autorelease];
    [gradientView setAltVerticalGradient:gradient];
    [gradientView setTopBorder:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]];
    [gradientView setTopBorder2:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
    
    // Task Manager
    [_progressDivider setColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
    [_progressDivider setBotBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:0.8]];
    [_progressButton setTarget:[[core win] taskManagerViewController]];
    [_progressButton setAction:@selector(cancelTask)];
    [self setProgressHidden:TRUE];
    [self setProgressTitle:@"Scanning for Updates..."];
    
	[self updateControls];
    [self updateLayout];
}

// == Artwork ==============================================

- (NSImageView *)albumArtView {
    return albumArtView;
}

// == Update ===============================================

- (void)updateLayout {
    [_volumeButton setHidden:[[core win] miniPlayer]];
    [_artistAlbumField setHidden:![[core win] miniPlayer]];
    if (![[core win] miniPlayer]) {
        [_containerView removeFromSuperview];
        for (NSView *i in [NSArray arrayWithObjects:playPause, next, previous, shuffle, repeat, nil]) {
            [i removeFromSuperview];
            [[self view] addSubview:i];
        }
        
        NSRect frame = [previous frame];
        frame.origin.x = 25;
        frame.origin.y = floor([[self view] frame].size.height/2 - [previous frame].size.height/2);
        [previous setFrame:frame];
        [previous setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
        
        frame = [playPause frame];
        frame.origin.x = floor([previous frame].origin.x + [previous frame].size.width - 3);
        frame.origin.y = floor([[self view] frame].size.height/2 - [playPause frame].size.height/2);
        [playPause setFrame:frame];
        [playPause setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
        
        frame = [next frame];
        frame.origin.x = floor([playPause frame].origin.x + [playPause frame].size.width - 3);
        frame.origin.y = floor([[self view] frame].size.height/2 - [next frame].size.height/2);
        [next setFrame:frame];
        [next setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
        
        frame = [_volumeButton frame];
        frame.origin.x = 160;
        frame.origin.y = floor([[self view] frame].size.height/2 - [_volumeButton frame].size.height/2 + 1);
        [_volumeButton setFrame:frame];
        [_volumeButton setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
        
        frame = [_volumeSlider frame];
        frame.origin.x = floor([_volumeButton frame].origin.x + [_volumeButton frame].size.width - 5);
        frame.origin.y = floor([[self view] frame].size.height/2 - [_volumeSlider frame].size.height/2);
        [_volumeSlider setFrame:frame];
        [_volumeSlider setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin];
        
        frame = [repeat frame];
        frame.origin.x = floor([[self view] frame].size.width - 25 - [repeat frame].size.width);
        frame.origin.y = floor([[self view] frame].size.height/2 - [repeat frame].size.height/2);
        [repeat setFrame:frame];
        [repeat setAutoresizingMask:NSViewMinYMargin|NSViewMinXMargin];
        
        frame = [shuffle frame];
        frame.origin.x = floor([repeat frame].origin.x - 10 - [shuffle frame].size.width);
        frame.origin.y = floor([[self view] frame].size.height/2 - [shuffle frame].size.height/2);
        [shuffle setFrame:frame];
        [shuffle setAutoresizingMask:NSViewMinYMargin|NSViewMinXMargin];
        
        frame = [_box frame];
        frame.origin.x = 300;
        frame.origin.y = floor([[self view] frame].size.height/2 - 42/2);
        frame.size.width = [[self view] frame].size.width - 390;
        frame.size.height = 42;
        [_box setFrame:frame];
        
        frame = [titleButton frame];
        frame.origin.x = 25;
        frame.origin.y = 17;
        frame.size.width = [_box frame].size.width - 50 - 80;
        [titleButton setFrame:frame];
        
        frame = [controlSlider frame];
        frame.origin.x = 17;
        frame.origin.y = 5;
        frame.size.width = [_box frame].size.width - 34;
        [controlSlider setFrame:frame];
        
        frame = [duration frame];
        frame.size.width = 80;
        frame.origin.y = 15;
        frame.origin.x = [_box frame].size.width - frame.size.width - 25;
        [duration setFrame:frame];
    } else {
        [_containerView removeFromSuperview];
        [[self view] addSubview:_containerView];
        [_box addSubview:_artistAlbumField];
        
        for (NSView *i in [NSArray arrayWithObjects:playPause, next, previous, shuffle, repeat, nil]) {
            [i removeFromSuperview];
            [_containerView addSubview:i];
        }
        
        NSRect frame;
        frame = [_containerView frame];
        frame.origin.x = floor([[self view] frame].size.width/2 - [_containerView frame].size.width/2);
        frame.origin.y = floor(45 - [_containerView frame].size.height/2);
        [_containerView setFrame:frame];
        
        frame = [playPause frame];
        frame.origin.x = floor([_containerView frame].size.width/2 - [playPause frame].size.width/2);
        frame.origin.y = floor(20 - [playPause frame].size.height/2);
        [playPause setFrame:frame];
        [playPause setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [previous frame];
        frame.origin.x = floor([playPause frame].origin.x - [previous frame].size.width + 3);
        frame.origin.y = floor(20 - [previous frame].size.height/2);
        [previous setFrame:frame];
        [previous setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [next frame];
        frame.origin.x = floor([playPause frame].origin.x + [playPause frame].size.width - 3);
        frame.origin.y = floor(20 - [next frame].size.height/2);
        [next setFrame:frame];
        [next setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [repeat frame];
        frame.origin.x = floor([playPause frame].origin.x + [playPause frame].size.width/2 - [repeat frame].size.width - 63);
        frame.origin.y = floor(20 - [repeat frame].size.height/2);
        [repeat setFrame:frame];
        [repeat setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [shuffle frame];
        frame.origin.x = floor([playPause frame].origin.x + [playPause frame].size.width/2 + 63);
        frame.origin.y = floor(20 - [shuffle frame].size.height/2);
        [shuffle setFrame:frame];
        [shuffle setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [_volumeSlider frame];
        frame.origin.x = floor([[self view] frame].size.width/2 - [_volumeSlider frame].size.width/2);
        frame.origin.y = 0;
        [_volumeSlider setFrame:frame];
        [_volumeSlider setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin];
        
        frame = [_box frame];
        frame.origin.x = 5;
        frame.origin.y = 63;
        frame.size.width = [[self view] frame].size.width - 10;
        frame.size.height = 42 + 15;
        [_box setFrame:frame];
        
        frame = [titleButton frame];
        frame.origin.x = 7;
        frame.origin.y = 34;
        frame.size.width = [_box frame].size.width - 14;
        [titleButton setFrame:frame];
        
        frame = [_artistAlbumField frame];
        frame.origin.x = 7;
        frame.origin.y = 17;
        frame.size.width = [_box frame].size.width - 14;
        [_artistAlbumField setFrame:frame];
        
        frame = [controlSlider frame];
        frame.origin.x = 35;
        frame.origin.y = 5;
        frame.size.width = [_box frame].size.width - 70;
        [controlSlider setFrame:frame];
        
        frame = [currentTime frame];
        frame.origin.x = 3;
        frame.origin.y = 1;
        frame.size.width = 40;
        [currentTime setFrame:frame];
        
        frame = [duration frame];
        frame.size.width = 40;
        frame.origin.x = [_box frame].size.width - frame.size.width - 3;
        frame.origin.y = 1;
        [duration setFrame:frame];
    }
    
    if (![self progressHidden] && ![[core win] miniPlayer]) {
        NSRect frame;
        frame = [titleButton frame];
        frame.size.width -= 165;
        [titleButton setFrame:frame];
        
        frame = [currentTime frame];
        frame.origin.x -= 165;
        [currentTime setFrame:frame];
        
        frame = [duration frame];
        frame.origin.x -= 165;
        [duration setFrame:frame];
        
        frame = [controlSlider frame];
        frame.size.width -= 165;
        [controlSlider setFrame:frame];
        
        frame = [_progressDivider frame];
        frame.origin.x = [_box frame].size.width - 175;
        frame.origin.y = 12;
        frame.size.height = 15;
        [_progressDivider setFrame:frame];
        
        frame = [_progressTextField frame];
        frame.size.width = 125;
        frame.origin.x = [_box frame].size.width - 157;
        frame.origin.y = 10;
        [_progressTextField setFrame:frame];
        
        frame = [_progressPercentTextField frame];
        frame.size.width = 30;
        frame.origin.x = [_box frame].size.width - 40;
        frame.origin.y = 10;
        [_progressPercentTextField setFrame:frame];
        
        frame = [_progressButton frame];
        frame.origin.x = [_box frame].size.width - 173;
        frame.origin.y = 12;
        [_progressButton setFrame:frame];
    } else if (![self progressHidden] && [[core win] miniPlayer]) {
        NSRect frame;
        frame = [titleButton frame];
        frame.size.width -= 37;
        [titleButton setFrame:frame];
        
        frame = [_artistAlbumField frame];
        frame.size.width -= 37;
        [_artistAlbumField setFrame:frame];
        
        frame = [duration frame];
        frame.origin.x -= 37;
        [duration setFrame:frame];
        
        frame = [controlSlider frame];
        frame.size.width -= 37;
        [controlSlider setFrame:frame];
        
        frame = [_progressDivider frame];
        frame.origin.x = [_box frame].size.width - 42;
        frame.origin.y = 11;
        frame.size.height = 30;
        [_progressDivider setFrame:frame];
        
        frame = [_progressPercentTextField frame];
        frame.size.width = 30;
        frame.origin.x = [_box frame].size.width - 39;
        frame.origin.y = 18;
        [_progressPercentTextField setFrame:frame];
    }
    
    if ([[core win] miniPlayer]) {
        [_progressTextField setHidden:TRUE];
        [_progressButton setHidden:TRUE];
    } else {
        [_progressTextField setHidden:_progressHidden];
        [_progressButton setHidden:_progressHidden];
    }
    [_progressDivider setHidden:_progressHidden];
    [_progressPercentTextField setHidden:_progressHidden];
    
    [self updateControls];
}

- (void)updateControls {
    if ([now currentIndex] == 0) {
        [duration setHidden:TRUE];
        [currentTime setHidden:TRUE];
        [titleButton setHidden:TRUE];
    } else {
        [duration setHidden:FALSE];
        [currentTime setHidden:FALSE];
        [titleButton setHidden:FALSE];
    }

	[icon setHidden:([now currentIndex] != 0)];
    [controlSlider setHidden:([now currentIndex] == 0)];
	[ratingControl setHidden:([now currentIndex] == 0)];
	
    if (![now shuffle]) {
        [shuffle setImage:[NSImage imageNamed:@"Shuffle"]];
    } else {
        [shuffle setImage:[NSImage imageNamed:@"ShuffleAlt"]];
    }
    if (![now repeat]) {
        [repeat setImage:[NSImage imageNamed:@"Repeat"]];
    } else {
        [repeat setImage:[NSImage imageNamed:@"RepeatAlt"]];
    }
    
    // title
    if ([now currentIndex] != 0) {
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.6]];
        [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
        NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
        if ([[core win] miniPlayer]) {
            [align setAlignment:NSCenterTextAlignment];
        } else {
            [align setAlignment:NSLeftTextAlignment];
        }
        NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [NSFont fontWithName:@"LucidaGrande-Bold" size:11], NSFontAttributeName,
                                                [NSColor colorWithDeviceWhite:0.1 alpha:1.0], NSForegroundColorAttributeName,
                                                align, NSParagraphStyleAttributeName,
                                                shadow, NSShadowAttributeName, nil];
        NSMutableDictionary *albumAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [NSFont fontWithName:@"LucidaGrande" size:11], NSFontAttributeName,
                                                [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                                align, NSParagraphStyleAttributeName,
                                                shadow, NSShadowAttributeName, nil];
        NSMutableDictionary *separatorAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    [NSFont fontWithName:@"LucidaGrande" size:11], NSFontAttributeName,
                                                    [NSColor colorWithDeviceWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
                                                    align, NSParagraphStyleAttributeName,
                                                    shadow, NSShadowAttributeName, nil];
        NSMutableDictionary *altTitleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                   [NSFont fontWithName:@"LucidaGrande-Bold" size:11], NSFontAttributeName,
                                                   [NSColor colorWithDeviceWhite:0.1 alpha:1.0], NSForegroundColorAttributeName,
                                                   align, NSParagraphStyleAttributeName,
                                                   shadow, NSShadowAttributeName, nil];
        NSMutableDictionary *altAlbumAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                   [NSFont fontWithName:@"LucidaGrande" size:11], NSFontAttributeName,
                                                   [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                                   align, NSParagraphStyleAttributeName,
                                                   shadow, NSShadowAttributeName, nil];        
        
        NSString *title = [[db library] valueForItem:[now currentItem] attr:PRItemAttrTitle];
        NSString *artist;
        if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
            artist = [[db library] valueForItem:[now currentItem] attr:PRItemAttrAlbumArtist];
        } else {
            artist = [[db library] valueForItem:[now currentItem] attr:PRItemAttrArtist];
        }
        NSString *album = [[db library] valueForItem:[now currentItem] attr:PRItemAttrAlbum];
        if ([artist isEqualToString:@""]) {
            artist = @"Unknown Artist";
        }
        if ([album isEqualToString:@""]) {
            album = @"Unknown Album";
        }
        
        if (![[core win] miniPlayer]) {
            NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:title attributes:titleAttributes] autorelease];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" - " attributes:separatorAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:album attributes:albumAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" - " attributes:separatorAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:artist attributes:albumAttributes] autorelease]];
            [titleButton setAttrString:attrString];
            
            attrString = [[[NSMutableAttributedString alloc] initWithString:title attributes:altTitleAttributes] autorelease];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" - " attributes:separatorAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:album attributes:altAlbumAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" - " attributes:separatorAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:artist attributes:altAlbumAttributes] autorelease]];
            [titleButton setAltAttrString:attrString];
            
            [_artistAlbumField setStringValue:@""];
        } else {
            NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:title attributes:titleAttributes] autorelease];
            [titleButton setAttrString:attrString];
            attrString =  [[[NSMutableAttributedString alloc] initWithString:title attributes:altTitleAttributes] autorelease];
            [titleButton setAltAttrString:attrString];
            
            attrString = [[[NSMutableAttributedString alloc] initWithString:album attributes:albumAttributes] autorelease];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" - " attributes:separatorAttributes] autorelease]];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:artist attributes:albumAttributes] autorelease]];
            [_artistAlbumField setAttributedStringValue:attrString];
        }
    } else {
        [_artistAlbumField setStringValue:@""];
    }
    
        
    // Rating
    int rating_;
	if ([now currentIndex] == 0) {
		rating_ = 0;
	} else {
        rating_ = [[[db library] valueForItem:[now currentItem] attr:PRItemAttrRating] intValue];
        rating_ = floor(rating_ / 20.0);
	}
    [ratingControl setSelectedSegment:rating_];
    
    // AlbumArt
    NSImage *albumArt = nil;
	if ([now currentIndex] != 0) {
		albumArt = [[db albumArtController] artworkForItem:[now currentItem]];
        if (!albumArt) {
            albumArt = [NSImage imageNamed:@"PREmptyAlbumArt.png"];
        }
	} else {
        albumArt = [NSImage imageNamed:@"PRNothingPlaying.png"];
    }
    [albumArtView setImage:albumArt];
    [self updatePlayButton];
}

- (void)updatePlayButton {
    // Play button
    if ([[now mov] isPlaying]) {
		[playPause setImage:[NSImage imageNamed:@"PauseButton"]];
	} else {
        [playPause setImage:[NSImage imageNamed:@"PlayButton"]];
	}
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.3]];
	[shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSMutableParagraphStyle *rightAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [rightAlign setAlignment:NSRightTextAlignment];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont fontWithName:@"LucidaGrande" size:10], NSFontAttributeName,
                                [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                rightAlign, NSParagraphStyleAttributeName,
                                shadow, NSShadowAttributeName, nil];
    NSString *currentTime_ = [timeFormatter stringForObjectValue:[NSNumber numberWithLong:[[now mov] currentTime]]];
    NSAttributedString *timeAttrString = [[[NSAttributedString alloc] initWithString:currentTime_ attributes:attributes] autorelease];
    [currentTime setAttributedStringValue:timeAttrString];
    
    NSMutableParagraphStyle *leftAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [leftAlign setAlignment:NSLeftTextAlignment];
    NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"LucidaGrande" size:10], NSFontAttributeName,
                                 [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                 leftAlign, NSParagraphStyleAttributeName,
                                 shadow, NSShadowAttributeName, nil];
    NSString *duration_ = [timeFormatter stringForObjectValue:[NSNumber numberWithLong:[[now mov] duration]]];
    timeAttrString = [[[NSAttributedString alloc] initWithString:duration_ attributes:attributes2] autorelease];
    [duration setAttributedStringValue:timeAttrString];
    
    if (![[core win] miniPlayer]) {
        timeAttrString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ / %@",currentTime_, duration_] attributes:attributes] autorelease];
        [duration setAttributedStringValue:timeAttrString];
        [currentTime setStringValue:@""];
    }
}

- (void)volumeChanged:(NSNotification *)notification {
    float volume = [[now mov] volume];
    NSImage *image = nil;
    if (volume == 0) {
        image = [NSImage imageNamed:@"NowSpeaker1"];
    } else if (volume < 0.33) {
        image = [NSImage imageNamed:@"NowSpeaker1"];
    } else if (volume < 0.66) {
        image = [NSImage imageNamed:@"NowSpeaker2"];
    } else {
        image = [NSImage imageNamed:@"NowSpeaker3"];
    }
    [_volumeButton setImage:image];
}

// == Action ===============================================

- (void)setProgressHidden:(BOOL)progressHidden {
    BOOL update = (_progressHidden != progressHidden);
    _progressHidden = progressHidden;
    if (update) {
        [self updateLayout];
    }
}

- (BOOL)progressHidden {
    return _progressHidden;
}

- (void)setProgressTitle:(NSString *)progressTitle {
    NSShadow *shadow2 = [[[NSShadow alloc] init] autorelease];
	[shadow2 setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
	[shadow2 setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[centerAlign setAlignment:NSLeftTextAlignment];
    [centerAlign setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont systemFontOfSize:11], NSFontAttributeName,
                                 [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                 centerAlign, NSParagraphStyleAttributeName,				  
                                 shadow2, NSShadowAttributeName,
                                 nil];
	NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:progressTitle attributes:attributes2] autorelease];
	[_progressTextField setAttributedStringValue:attributedString];
}

- (void)setProgressPercent:(int)progressPercent {
//    if (progressPercent == 0) {
//        [_progressPercentTextField setAttributedStringValue:nil];
//        return;
//    }
    NSShadow *shadow2 = [[[NSShadow alloc] init] autorelease];
	[shadow2 setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
	[shadow2 setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[centerAlign setAlignment:NSCenterTextAlignment];
    [centerAlign setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont systemFontOfSize:11], NSFontAttributeName,
                                 [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                 centerAlign, NSParagraphStyleAttributeName,				  
                                 shadow2, NSShadowAttributeName,
                                 nil];
	NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d%%",progressPercent] attributes:attributes2] autorelease];
	[_progressPercentTextField setAttributedStringValue:attributedString];
}

- (void)showInLibrary {
    if (![now currentItem]) {
        return;
    }
    if (![[core win] miniPlayer]) {
        [[core win] setCurrentMode:PRLibraryMode];
        [[core win] setCurrentPlaylist:[[[db playlists] libraryList] intValue]];
        [[libraryViewController currentViewController] highlightFile:[[now currentItem] intValue]];
    } 
    [[[core win] nowPlayingViewController] higlightPlayingFile];
}

- (void)mute {
    [[now mov] setVolume:0];
}

@end
