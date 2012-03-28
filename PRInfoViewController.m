#import "PRInfoViewController.h"
#import "PRLibraryViewController.h"
#import "PRLibrary.h"
#import "PRAlbumArtController.h"
#import "PRDb.h"
#import "PRRatingCell.h"
#import "PRGradientView.h"
#import "PRNumberFormatter.h"
#import "PRStringFormatter.h"
#import "PRCore.h"
#import "PRTableViewController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRPathFormatter.h"
#import "PRKindFormatter.h"
#import "PRSizeFormatter.h"
#import "PRDateFormatter.h"
#import "PRTimeFormatter.h"
#import "PRBitRateFormatter.h"
#import "PRTagger.h"
#import "NSIndexSet+Extensions.h"
#import "NSNotificationCenter+Extensions.h"
#import "MAZeroingWeakRef.h"


#define CONTROLKEY @"control"
#define ITEMATTRKEY @"itemAttr"
#define FORMATTERKEY @"formatter"
#define NULLVALUEPLACEHOLDERKEY @"nullValuePlaceholder"
#define MULTIPLEVALUEPLACEHOLDERKEY @"multipleValuePlaceholder"
#define NOSELECTIONPLACEHOLDERKEY @"noSelectionPlaceholder"
#define KINDKEY @"kindKey"
#define NONEKIND 0
#define STRINGKIND 1
#define NUMBERKIND 2


@interface PRInfoViewController ()
/* Tab Control */
- (void)updateTabControl;
- (NSDictionary *)tabs;
- (void)tabAction:(id)sender;

/* Update */
- (void)update;

/* Accessors */
- (void)setValue:(id)value forAttribute:(PRItemAttr *)attribute;
- (id)valueForAttribute:(PRItemAttr *)attr;
- (void)toggleCompilation;

/* Misc */
- (NSArray *)tagControls;
@end


@implementation PRInfoViewController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
	if (!(self = [super initWithNibName:@"PRInfoView" bundle:nil])) {return nil;}
    _core = core;
    _db = [_core db];
    _numberFormatter = [[PRNumberFormatter alloc] init];
    _stringFormatter = [[PRStringFormatter alloc] init];
    _pathFormatter = [[PRPathFormatter alloc] init];
    _kindFormatter = [[PRKindFormatter alloc] init];
    _sizeFormatter = [[PRSizeFormatter alloc] init];
    _dateFormatter = [[PRDateFormatter alloc] init];
    _timeFormatter = [[PRTimeFormatter alloc] init];
    _bitrateFormatter = [[PRBitRateFormatter alloc] init];
    _mode = PRInfoModeTags;
    
    [[NSNotificationCenter defaultCenter] observeLibraryViewSelectionChanged:self sel:@selector(update)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(update)];
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_numberFormatter release];
    [_stringFormatter release];
    [_pathFormatter release];
    [_kindFormatter release];
	[_sizeFormatter release];
	[_dateFormatter release];
	[_timeFormatter release];
	[_bitrateFormatter release];
    [super dealloc];
}

- (void)awakeFromNib {
    [albumArtView addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    [[ratingControl cell] addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    
    [_compilationButton setTarget:self];
    [_compilationButton setAction:@selector(toggleCompilation)];
    
	for (NSDictionary *i in [self tagControls]) {
		PRItemAttr *itemAttr = [i valueForKey:ITEMATTRKEY];
		int kind = [[i valueForKey:KINDKEY] intValue];
		NSControl *control = [i valueForKey:CONTROLKEY];
		NSFormatter *formatter = [i valueForKey:FORMATTERKEY];
		
		MAZeroingWeakRef *selfRef = [MAZeroingWeakRef refWithTarget:self];
		if (kind == NUMBERKIND) {
			[NSNotificationCenter observe:NSTextDidEndEditingNotification object:control queue:nil block:^(NSNotification *note) {
				[(PRInfoViewController *)[selfRef target] setValue:[NSNumber numberWithInt:[[note object] intValue]] forKey:itemAttr];
			}];
		} else if (kind == STRINGKIND) {
			[NSNotificationCenter observe:NSTextDidEndEditingNotification object:control queue:nil block:^(NSNotification *note) {
				[(PRInfoViewController *)[selfRef target] setValue:[[note object] stringValue] forKey:itemAttr];
			}];
		}
		if (formatter != (id)[NSNull null]) {
			[control setFormatter:formatter];
		}
	}
    
    PRGradientView *view = (PRGradientView *)[self view];
    [view setTopBorder:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
    [view setTopBorder2:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
    [view setColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0]];
    [_border setTopBorder:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
    [_border setTopBorder2:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
    
    for (NSDictionary *i in [self tabs]) {
        NSButton *button = [i objectForKey:@"button"];
        PRInfoMode mode = [[i objectForKey:@"mode"] intValue];
        [button setTag:mode];
        [button setTarget:self];
        [button setAction:@selector(tabAction:)];
    }
    
    // rating
    [((PRRatingCell *)[ratingControl cell]) setShowDots:TRUE];
    
    [self update];
    [self updateTabControl];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if (object == [ratingControl cell] && [keyPath isEqualToString:@"objectValue"]) {
       if ([selection count] == 0) {
           return;
       }
       int rating = [ratingControl selectedSegment] * 20;
       for (NSNumber *i in selection) {
           [[_db library] setValue:[NSNumber numberWithInt:rating] forItem:i attr:PRItemAttrRating];
       }
       [[NSNotificationCenter defaultCenter] postItemsChanged:selection];
   } else if (object == albumArtView && [keyPath isEqualToString:@"objectValue"]) {
       [self setAlbumArt:[object objectValue]];
   }
}

// ========================================
// Tab Control

- (NSDictionary *)tabs {
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:PRInfoModeTags], @"mode", 
             _tagsView, @"view", 
             _tagsButton, @"button", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:PRInfoModeProperties], @"mode", 
             _propertiesView, @"view", 
             _propertiesButton, @"button", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:PRInfoModeLyrics], @"mode", 
             _lyricsView, @"view", 
             _lyricsButton, @"button", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:PRInfoModeArtwork], @"mode", 
             _artworkView, @"view", 
             _artworkButton, @"button", nil],
            nil];
}

- (void)updateTabControl {
    for (NSDictionary *i in [self tabs]) {
        BOOL isMode = ([[i objectForKey:@"mode"] intValue] == _mode);
        NSButton *button = [i objectForKey:@"button"];
        NSView *view = [i objectForKey:@"view"];
        [button setState:NSOffState];
        [view removeFromSuperview];
        if (isMode) {
            [button setState:NSOnState];
            NSRect frame = [view frame];
            frame.size.width = [[self view] frame].size.width - 120;
            frame.origin.x = 120;
            [view setFrame:frame];
            [[self view] addSubview:view];
        }
    }
}

- (void)tabAction:(id)sender {
    _mode = [sender tag];
    [self updateTabControl];
}

// ========================================
// Update

- (void)update {
    [selection release];
	selection = [[[[[_core win] libraryViewController] currentViewController] selection] retain];
    
    [ratingControl setHidden:([selection count] == 0)];
    
	for (NSDictionary *i in [self tagControls]) {
		id value = [self valueForAttribute:[i valueForKey:ITEMATTRKEY]];
		NSControl *field = [i valueForKey:CONTROLKEY];
		if (value == NSNoSelectionMarker) {
			[[field cell] setPlaceholderString:[i valueForKey:NOSELECTIONPLACEHOLDERKEY]];
			[field setStringValue:@""];
		} else if (value == NSMultipleValuesMarker) {
			[[field cell] setPlaceholderString:[i valueForKey:MULTIPLEVALUEPLACEHOLDERKEY]];
			[field setStringValue:@""];
		} else if (value == nil) {
			[[field cell] setPlaceholderString:[i valueForKey:NULLVALUEPLACEHOLDERKEY]];
			[field setStringValue:@""];
		} else {
			[field setObjectValue:value];
		}
		if ([[i valueForKey:KINDKEY] intValue] != NONEKIND) {
			[field setEnabled:[selection count] > 0];
		}
	}
	
    [albumArtView setImage:[self albumArt]];
    NSNumber *rating = [self valueForAttribute:PRItemAttrRating];
    if ([rating isKindOfClass:[NSNumber class]]) {
        [ratingControl setSelectedSegment:floor([rating intValue] / 20)];
    } else {
        [ratingControl setSelectedSegment:0];
    }
    
    NSNumber *compilation = [self valueForAttribute:PRItemAttrCompilation];
    if (compilation == NSMultipleValuesMarker) {
        [_compilationButton setState:NSMixedState];
    } else if (compilation == NSNoSelectionMarker) {
        [_compilationButton setState:NSOffState];
    } else if ([compilation boolValue] == TRUE) {
        [_compilationButton setState:NSOnState];
    } else if ([compilation boolValue] == FALSE) {
        [_compilationButton setState:NSOffState];
    }
    [_compilationButton setEnabled:(compilation != NSNoSelectionMarker)];
}

// ========================================
// Accessors

- (void)setValue:(id)value forAttribute:(PRItemAttr *)attribute {
    if ([selection count] == 0) {
		return;
	}
    for (NSNumber *i in selection) {
        [PRTagger setTag:value forAttribute:attribute URL:[[_db library] URLForItem:i]];
        [[_db library] updateTagsForItem:i];
    }
    [[NSNotificationCenter defaultCenter] postItemsChanged:selection];
    [[[[_core win] libraryViewController] currentViewController] highlightFiles:selection];
    [[NSOperationQueue mainQueue] addBlock:^{
		[self update];
	}];
}

- (id)valueForAttribute:(PRItemAttr *)attribute {	
	if ([selection count] == 0) {
		return NSNoSelectionMarker;
	}
    id firstResult = [[_db library] valueForItem:[selection objectAtIndex:0] attr:attribute];
    for (NSNumber *i in selection) {
        id result = [[_db library] valueForItem:i attr:attribute];
        if (![firstResult isEqual:result]) {
            return NSMultipleValuesMarker;
        }
    }
    if ([firstResult isKindOfClass:[NSNumber class]] && [firstResult intValue] == 0) {
        return nil;
    } else if ([firstResult isKindOfClass:[NSString class]] && [firstResult length] == 0) {
        return nil;
    }
	return firstResult;
}

- (void)setAlbumArt:(NSImage *)value {
    NSData *data = [value TIFFRepresentation];
    if (!value) {
        data = [NSData data];
    }
    [self setValue:data forAttribute:PRItemAttrArtwork];
}

- (NSImage *)albumArt {
    if ([selection count] == 0) {
        return nil;
    }
    NSImage *albumArt = [[_db albumArtController] artworkForItem:[selection objectAtIndex:0]];
    return albumArt;
}

- (void)toggleCompilation {
    NSNumber *compilation = [self valueForAttribute:PRItemAttrCompilation];
    if (compilation == NSMultipleValuesMarker || [compilation intValue] == 1) {
        [self setValue:[NSNumber numberWithInt:0] forAttribute:PRItemAttrCompilation];
    } else {
        [self setValue:[NSNumber numberWithInt:1] forKey:PRItemAttrCompilation];
    }
}

// ========================================
// misc

- (NSArray *)tagControls {
    static NSMutableArray *array = nil;
    if (!array) {
        array = [[NSMutableArray alloc] init];
        
        typedef struct {
            NSTextField *control;
            PRItemAttr *itemAttr;
			NSFormatter *formatter;
            NSString *nullValuePlaceholder;
            NSString *multipleValuePlaceholder;
            NSString *noSelectionPlaceholder;
			int kind;
        } properties;
        
        int count = 14;
        properties p[] = {            
            {titleField, PRItemAttrTitle, _stringFormatter, nil, nil, @"No Selection", STRINGKIND},
			{artistField, PRItemAttrArtist, _stringFormatter, nil, nil, nil, STRINGKIND},
			{albumArtistField, PRItemAttrAlbumArtist, _stringFormatter, nil, nil, nil, STRINGKIND},
			{albumField, PRItemAttrAlbum, _stringFormatter, nil, nil, nil, STRINGKIND},
			{yearField, PRItemAttrYear, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{bpmField, PRItemAttrBPM, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{trackField, PRItemAttrTrackNumber, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{trackCountField, PRItemAttrTrackCount, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{discField, PRItemAttrDiscNumber, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{discCountField, PRItemAttrDiscCount, _numberFormatter, nil, nil, nil, NUMBERKIND},
			{composerField, PRItemAttrComposer, _stringFormatter, nil, nil, nil, STRINGKIND},
			{commentsField, PRItemAttrComments, _stringFormatter, nil, nil, nil, STRINGKIND},
			{genreField, PRItemAttrGenre, _stringFormatter, nil, nil, nil, STRINGKIND},
			{_lyricsField, PRItemAttrLyrics, nil, nil, nil, nil, STRINGKIND},
			{_pathField, PRItemAttrPath, _pathFormatter, nil, nil, nil, NONEKIND},
			{_kindField, PRItemAttrKind, _kindFormatter, nil, nil, @"No Selection", NONEKIND},
			{_sizeField, PRItemAttrSize, _sizeFormatter, nil, nil, nil, NONEKIND},
			{_lastModifiedField, PRItemAttrLastModified, _dateFormatter, nil, nil, nil, NONEKIND},
			{_dateAddedField, PRItemAttrDateAdded, _dateFormatter, nil, nil, nil, NONEKIND},
			{_lengthField, PRItemAttrTime, _timeFormatter, nil, nil, nil, NONEKIND},
			{_bitrateField, PRItemAttrBitrate, _bitrateFormatter, nil, nil, nil, NONEKIND},
			{_channelsField, PRItemAttrChannels, _numberFormatter, nil, nil, nil, NONEKIND},
			{_sampleRateField, PRItemAttrSampleRate, _numberFormatter, nil, nil, nil, NONEKIND},
			{_playCountField, PRItemAttrPlayCount, _numberFormatter, nil, nil, nil, NONEKIND},
			{_lastPlayedField, PRItemAttrLastPlayed, _dateFormatter, nil, nil, nil, NONEKIND},
        };
        
        for (int i = 0; i < count; i++) {
			if (!p[i].formatter) {
				p[i].formatter = (id)[NSNull null];
			}
			if (!p[i].nullValuePlaceholder) {
				p[i].nullValuePlaceholder = @"None";
			}
			if (!p[i].multipleValuePlaceholder) {
				p[i].multipleValuePlaceholder = @"Multiple Values";
			}
			if (!p[i].noSelectionPlaceholder) {
				p[i].noSelectionPlaceholder = @"-";
			}
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:p[i].control forKey:CONTROLKEY];
			[dict setValue:p[i].itemAttr forKey:ITEMATTRKEY];
			[dict setValue:p[i].formatter forKey:FORMATTERKEY];
			[dict setValue:p[i].nullValuePlaceholder forKey:NULLVALUEPLACEHOLDERKEY];
			[dict setValue:p[i].multipleValuePlaceholder forKey:MULTIPLEVALUEPLACEHOLDERKEY];
			[dict setValue:p[i].noSelectionPlaceholder forKey:NOSELECTIONPLACEHOLDERKEY];
			[dict setValue:[NSNumber numberWithInt:p[i].kind] forKey:KINDKEY];
            [array addObject:dict];
        }
    }
    return array;
}

@end
