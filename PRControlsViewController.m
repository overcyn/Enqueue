#import "PRControlsViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRNowPlayingController.h"
#import "PRMoviePlayer.h"
#import "PRRatingCell.h"
#import "PRAlbumArtController.h"
#import "NSImage+FlippedDrawing.h"
#import "PRGradientView.h"
#import "BWTexturedSlider.h"
#import "PRSliderCell.h"
#import "PRLibraryViewController.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRTimeFormatter.h"

@implementation PRControlsViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_;
{
    self = [super initWithNibName:@"PRControlsView" bundle:nil];
	if (self) {
        core = core_;
		db = [[core_ db] retain];
		now = [[core_ now] retain];
        libraryViewController = [[[core_ win] libraryViewController] retain];
	}
	return self;
}

- (void)dealloc
{
    [timeFormatter release];
    [db release];
    [now release];
    [super dealloc];
}

- (void)awakeFromNib 
{
    [self setShowsArtwork:TRUE];
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0.0], 0.0, 
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0.0], 1.0,
                             nil] autorelease];
    [gradientView setAlternateVerticalGradient:gradient];
    
	// rating
	[((PRRatingCell *)[ratingControl cell]) setShowDots:TRUE];
    [[ratingControl cell] addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
	
	// bind time and duration textfields
//	[currentTime bind:@"value" toObject:now withKeyPath:@"mov.currentTime" options:nil];
//	[duration bind:@"value" toObject:now withKeyPath:@"mov.duration" options:nil];
	
	// bind time and volume sliders
    [controlSlider setCell:[[[PRSliderCell alloc] init] autorelease]];
	[controlSlider setMinValue:0.0];
	[controlSlider bind:@"maxValue" toObject:now withKeyPath:@"mov.duration" options:nil];
	[controlSlider bind:@"value" toObject:now withKeyPath:@"mov.currentTime" options:nil];
	
	[volumeSlider setMaxValue:1];
	[volumeSlider setMinValue:0];
	[volumeSlider bind:@"value" toObject:now withKeyPath:@"mov.volume" options:nil];
    [(BWTexturedSlider *)volumeSlider setIndicatorIndex:3];
    
	// bind buttons
	NSDictionary *options = 
      [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:FALSE] 
                                  forKey:NSConditionallySetsEnabledBindingOption];
	[playPause bind:@"target" toObject:now withKeyPath:@"playPause" options:options];
	[next bind:@"target" toObject:now withKeyPath:@"playNext" options:options];
	[previous bind:@"target" toObject:now withKeyPath:@"playPrevious" options:options];
    [shuffle bind:@"target" toObject:now withKeyPath:@"toggleShuffle" options:options];
	[repeat bind:@"target" toObject:now withKeyPath:@"toggleRepeat" options:options];

    [now addObserver:self forKeyPath:@"shuffle" options:0 context:nil];
    [now addObserver:self forKeyPath:@"repeat" options:0 context:nil];
    [[now mov] addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
    [now addObserver:self forKeyPath:@"currentIndex" options:0 context:nil];
    
    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:[titleField frame]
                                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow  
                                                                   owner:self 
                                                                userInfo:nil] autorelease];
    [gradientView addTrackingArea:trackingArea];
    
	// register for observers
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(update) 
												 name:PRTagsDidChangeNotification 
											   object:nil];
    
    [now addObserver:self forKeyPath:@"mov.currentTime" options:0 context:self];
    
    [titleButton setTarget:self];
    [titleButton setAction:@selector(showInLibrary)];
    
    timeFormatter = [[PRTimeFormatter alloc] init];
    
	[self update];
}

// ========================================
// Update
// ========================================

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if ((object == now && [keyPath isEqualToString:@"currentIndex"]) || 
        (object == [now mov] && [keyPath isEqualToString:@"isPlaying"]) ||
        (object == now && [keyPath isEqualToString:@"shuffle"]) ||
        (object == now && [keyPath isEqualToString:@"repeat"])) {
        [self update];
    } else if (object == now && [keyPath isEqualToString:@"mov.currentTime"]) {
        [self updatePlayButton];
    } else if (object == [ratingControl cell] && [keyPath isEqualToString:@"objectValue"]) {
        int newRating = [[ratingControl objectValue] intValue] * 20;
        if (newRating > 100 || newRating < 0 || [now currentIndex] == 0) {
            return;
        }
        [[db library] setIntValue:newRating forFile:[now currentFile] attribute:PRRatingFileAttribute _error:nil];
        NSDictionary *userInfo = 
            [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSNumber numberWithInt:[now currentFile]]]
                                        forKey:@"files"];
        [[NSNotificationCenter defaultCenter] postNotificationName:PRTagsDidChangeNotification 
                                                            object:self
                                                          userInfo:userInfo];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if ([now currentIndex] != 0) {
        [[NSCursor pointingHandCursor] set];
    }
    mouseInTitle = TRUE;
    [self update];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[NSCursor arrowCursor] set];
    mouseInTitle = FALSE;
    [self update];
}

- (void)update
{
    if ([now currentIndex] == 0) {
        [duration setHidden:TRUE];
        [currentTime setHidden:TRUE];
        [titleButton setHidden:TRUE];
    } else {
        [duration setHidden:FALSE];
        [currentTime setHidden:FALSE];
        [titleButton setHidden:FALSE];
    }
    
	[(PRSliderCell *)[controlSlider cell] setIndicator:([now currentIndex] != 0)];
    
	[icon setHidden:([now currentIndex] != 0)];
	[ratingControl setHidden:([now currentIndex] == 0)];
	
    if (![now shuffle]) {
        [shuffle setImage:[NSImage imageNamed:@"PRShuffleIcon.png"]];
    } else {
        [shuffle setImage:[NSImage imageNamed:@"PRShuffleOffIcon.png"]];
    }
    if (![now repeat]) {
        [repeat setImage:[NSImage imageNamed:@"PRRepeatIcon.png"]];
    } else {
        [repeat setImage:[NSImage imageNamed:@"PRRepeatOffIcon.png"]];
    }
    
    // title
    NSString *title;
    NSString *artist;
    NSString *album;
    if ([now currentIndex] == 0) {
        title = @"";
        artist = @"";
        album = @"";
    } else {
        [[db library] value:&title forFile:[now currentFile] attribute:PRTitleFileAttribute _error:nil];
        [[db library] value:&artist forFile:[now currentFile] attribute:PRArtistFileAttribute _error:nil];
        [[db library] value:&album forFile:[now currentFile] attribute:PRAlbumFileAttribute _error:nil];
        if (!title) {
            title = @"";
        }
        if (!artist || [artist isEqualToString:@""]) {
            artist = @"Unknown Artist";
        }
        if (!album || [album isEqualToString:@""]) {
            album = @"Unknown Album";
        }
    }
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.7]];
	[shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [centerAlign setAlignment:NSCenterTextAlignment];
    
    NSMutableDictionary *titleAttributes = 
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       [NSFont fontWithName:@"LucidaGrande-Bold" size:11], NSFontAttributeName,
       [NSColor colorWithDeviceWhite:0.1 alpha:1.0], NSForegroundColorAttributeName,
       centerAlign, NSParagraphStyleAttributeName,
       shadow, NSShadowAttributeName,
       nil];
    
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.4]];
    NSMutableDictionary *albumAttributes = 
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       [NSFont fontWithName:@"LucidaGrande" size:11], NSFontAttributeName,
       [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
       centerAlign, NSParagraphStyleAttributeName,
       shadow, NSShadowAttributeName,
       nil];
    
    if (mouseInTitle) {
        [titleAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] 
                            forKey:NSUnderlineStyleAttributeName];
    }
    
    [titleField setAttributedStringValue:[[[NSMutableAttributedString alloc] initWithString:title attributes:titleAttributes] autorelease]];
    [artistField setAttributedStringValue:[[[NSMutableAttributedString alloc] initWithString:artist attributes:albumAttributes] autorelease]];
    [albumField setAttributedStringValue:[[[NSMutableAttributedString alloc] initWithString:album attributes:albumAttributes] autorelease]];
    
    // Rating
    int rating_;
	if ([now currentIndex] == 0) {
		rating_ = 0;
	} else {		
		[[db library] intValue:&rating_ forFile:[now currentFile] attribute:PRRatingFileAttribute _error:nil];
        rating_ = floor(rating_ / 20.0);
	}
    [ratingControl setSelectedSegment:rating_];
    
    // AlbumArt
    NSImage *albumArt;
	if ([now currentIndex] == 0) {
		albumArt = nil;
	} else {
		[[db albumArtController] albumArt:&albumArt forFile:[now currentFile] _error:nil];
	}
	if (albumArt == nil || ![albumArt isValid]) {
		albumArt = [NSImage imageNamed:@"PRLightAlbumArt"];
	}
    [albumArtView setImage:albumArt];
    
    [self updatePlayButton];
}

- (void)updatePlayButton
{
    if ([[now mov] isPlaying]) {
		[playPause setImage:[NSImage imageNamed:@"PRPauseIcon.png"]];
	} else {
        [playPause setImage:[NSImage imageNamed:@"PRPlayIcon.png"]];
	}
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.3]];
	[shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSMutableParagraphStyle *leftAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [leftAlign setAlignment:NSLeftTextAlignment];
    NSMutableParagraphStyle *rightAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [rightAlign setAlignment:NSRightTextAlignment];
    
    NSMutableDictionary *attributes = 
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"LucidaGrande" size:9.5], NSFontAttributeName,
         [NSColor colorWithDeviceWhite:0.25 alpha:1.0], NSForegroundColorAttributeName,
         leftAlign, NSParagraphStyleAttributeName,
         shadow, NSShadowAttributeName,
         nil];
    
    NSString *currentTime_ = [timeFormatter stringForObjectValue:[NSNumber numberWithLong:[[now mov] currentTime]]];
    NSAttributedString *currentTimeAttributedString = [[[NSAttributedString alloc] initWithString:currentTime_ attributes:attributes] autorelease];
    [currentTime setAttributedStringValue:currentTimeAttributedString];
    
    [attributes setObject:rightAlign forKey:NSParagraphStyleAttributeName];
    
    NSString *duration_ = [timeFormatter stringForObjectValue:[NSNumber numberWithLong:[[now mov] duration]]];
    NSAttributedString *durationAttributedString = [[[NSAttributedString alloc] initWithString:duration_ attributes:attributes] autorelease];
    [duration setAttributedStringValue:durationAttributedString];
}

// ========================================
// Action
// ========================================

- (void)showInLibrary
{
    [[core win] setCurrentMode:PRLibraryMode];
    [[core win] setCurrentPlaylist:[[db playlists] libraryPlaylist]];
    [libraryViewController highlightFile:[now currentFile]];
}

- (void)setShowsArtwork:(BOOL)showsArtwork
{
    NSGradient *gradient;
    if (showsArtwork) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.73 alpha:1.0], 0.0, 
//                     [NSColor colorWithCalibratedWhite:0.80 alpha:1.0], 0.3,
                     [NSColor colorWithCalibratedWhite:0.685 alpha:1.0], 0.65,
                     [NSColor colorWithCalibratedWhite:0.59 alpha:1.0], 0.80,
                     [NSColor colorWithCalibratedWhite:0.52 alpha:1.0], 1.0,
                     nil] autorelease];
    } else {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.73 alpha:1.0], 0.0, 
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0], 0.4,
                     [NSColor colorWithCalibratedWhite:0.695 alpha:1.0], 0.7,
                     [NSColor colorWithCalibratedWhite:0.56 alpha:1.0], 1.0,
                     nil] autorelease];
    }
    [gradientView setVerticalGradient:gradient];
    
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.1], 0.0, 
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0], 0.2,
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0], 0.8,
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.1], 1.0,
                 nil] autorelease];
    [gradientView setHorizontalGradient:gradient];
}


@end