#import "PRInfoViewController.h"
#import "NSArray+Extensions.h"
#import "NSIndexSet+Extensions.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRAlbumArtController.h"
#import "PRBitRateFormatter.h"
#import "PRCore.h"
#import "PRDateFormatter.h"
#import "PRDb.h"
#import "PRGradientView.h"
#import "PRKindFormatter.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRLibraryViewController.h"
#import "PRMainWindowController.h"
#import "PRNumberFormatter.h"
#import "PRPathFormatter.h"
#import "PRRatingCell.h"
#import "PRSizeFormatter.h"
#import "PRStringFormatter.h"
#import "PRTableViewController.h"
#import "PRTagger.h"
#import "PRTimeFormatter.h"


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


@implementation PRInfoViewController {
    __weak PRCore *_core;
    __weak PRDb *_db;
    
    IBOutlet NSTextField *titleField;
    IBOutlet NSTextField *artistField;  
    IBOutlet NSTextField *albumArtistField; 
    IBOutlet NSTextField *albumField;
    IBOutlet NSTextField *yearField;
    IBOutlet NSTextField *bpmField; 
    IBOutlet NSTextField *trackField;   
    IBOutlet NSTextField *trackCountField;      
    IBOutlet NSTextField *discField;
    IBOutlet NSTextField *discCountField;
    IBOutlet NSTextField *composerField;    
    IBOutlet NSTextField *commentsField;
    IBOutlet NSTextField *genreField;
    IBOutlet NSButton *_compilationButton;
    
    IBOutlet NSTextField *_pathField;
    IBOutlet NSTextField *_kindField;
    IBOutlet NSTextField *_sizeField;
    IBOutlet NSTextField *_lastModifiedField;
    IBOutlet NSTextField *_dateAddedField;
    IBOutlet NSTextField *_lengthField;
    IBOutlet NSTextField *_bitrateField;
    IBOutlet NSTextField *_channelsField;
    IBOutlet NSTextField *_sampleRateField;
    IBOutlet NSTextField *_playCountField;
    IBOutlet NSTextField *_lastPlayedField;
    
    IBOutlet NSTextField *_lyricsField;
    
    IBOutlet NSSegmentedControl *ratingControl;
    IBOutlet NSImageView *albumArtView;
    
    IBOutlet NSButton *_tagsButton;
    IBOutlet NSButton *_propertiesButton;
    IBOutlet NSButton *_lyricsButton;
    IBOutlet NSButton *_artworkButton;
    
    IBOutlet NSView *_tagsView;
    IBOutlet NSView *_propertiesView;
    IBOutlet NSView *_lyricsView;
    IBOutlet NSView *_artworkView;
    
    IBOutlet PRGradientView *_border;
        
    PRInfoMode _mode;
    
    NSArray *_controls;
    NSArray *_propertyControls;
    NSArray *labels;
    PRBitRateFormatter *_bitrateFormatter;
    PRDateFormatter *_dateFormatter;
    PRSizeFormatter *_sizeFormatter;
    PRPathFormatter *_pathFormatter;
    PRKindFormatter *_kindFormatter;
    PRTimeFormatter *_timeFormatter;
    PRNumberFormatter *_numberFormatter;
    PRStringFormatter *_stringFormatter;
    
    NSArray *_selection;
    BOOL _didChange;
}

#pragma mark - Initialization

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
    
    [NSNotificationCenter addObserver:self selector:@selector(update) name:PRLibraryViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(update)];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [albumArtView addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    [[ratingControl cell] addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    
    [_compilationButton setTarget:self];
    [_compilationButton setAction:@selector(toggleCompilation)];
    
    for (NSDictionary *i in [self tagControls]) {
        NSControl *control = [i valueForKey:CONTROLKEY];
        NSFormatter *formatter = [i valueForKey:FORMATTERKEY];
        [NSNotificationCenter addObserver:self selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:control];
        [NSNotificationCenter addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:control];
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
    [((PRRatingCell *)[ratingControl cell]) setShowDots:YES];
    
    [self update];
    [self updateTabControl];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if (object == [ratingControl cell] && [keyPath isEqualToString:@"objectValue"]) {
       [self setValue:[NSNumber numberWithInt:[ratingControl selectedSegment] * 20] forAttribute:PRItemAttrRating];
   } else if (object == albumArtView && [keyPath isEqualToString:@"objectValue"]) {
       NSData *data = [NSData data];
       if ([object objectValue]) {
           data = [[object objectValue] TIFFRepresentation];
       }
       [self setValue:data forAttribute:PRItemAttrArtwork];
   }
}

#pragma mark - Tab Control

- (NSArray *)tabs {
    return @[@{@"mode":@(PRInfoModeTags), @"view":_tagsView, @"button":_tagsButton},
             @{@"mode":@(PRInfoModeProperties), @"view":_propertiesView, @"button":_propertiesButton},
             @{@"mode":@(PRInfoModeLyrics), @"view":_lyricsView, @"button":_lyricsButton},
             @{@"mode":@(PRInfoModeArtwork), @"view":_artworkView, @"button":_artworkButton}];
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

#pragma mark - Update

- (void)update {
    _selection = [[[[_core win] libraryViewController] currentViewController] selection];
    
    [ratingControl setHidden:([_selection count] == 0)];
    
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
            [field setEnabled:[_selection count] > 0];
        }
    }
    
    NSImage *albumArt = nil;
    if ([_selection count] != 0) {
        albumArt= [[_db albumArtController] artworkForItem:[_selection objectAtIndex:0]];
    }
    [albumArtView setImage:albumArt];
    
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
    } else if ([compilation boolValue] == YES) {
        [_compilationButton setState:NSOnState];
    } else if ([compilation boolValue] == NO) {
        [_compilationButton setState:NSOffState];
    }
    [_compilationButton setEnabled:(compilation != NSNoSelectionMarker)];
    
    _didChange = NO;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (!_didChange) {
        _didChange = NO;
        return;
    }
    NSTextField *field = [notification object];
    NSDictionary *dict = [[self tagControls] objectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj objectForKey:CONTROLKEY] == field;
    }];
    if (!dict) {
        @throw NSInvalidArgumentException;
    }
    int kind = [[dict objectForKey:KINDKEY] intValue];
    PRItemAttr *attr = [dict objectForKey:ITEMATTRKEY];
    if ([field objectValue] == [self valueForAttribute:attr]) {
        return;
    }
    if (kind == STRINGKIND) {
        [self setValue:[field stringValue] forAttribute:attr];
    } else if (kind == NUMBERKIND) {
        [self setValue:[NSNumber numberWithInt:[field intValue]] forAttribute:attr];
    } else {
        @throw NSInternalInconsistencyException;
    }
}

- (void)controlTextDidChange:(NSNotification *)note {
    _didChange = YES;
}

#pragma mark - Accessors

- (void)setValue:(id)value forAttribute:(PRItemAttr *)attribute {
    if ([_selection count] == 0) {
        return;
    }
    for (NSNumber *i in _selection) {
        if (attribute == PRItemAttrRating) {
            [[_db library] setValue:value forItem:i attr:PRItemAttrRating];
            continue;
        }
        [PRTagger setTag:value forAttribute:attribute URL:[[_db library] URLForItem:i]];
        [PRTagger updateTagsForItem:i database:_db];
    }
    // postItemsChanged clears _selection so we save prior selection so we can highlight
    NSArray *selection = _selection;
    [[NSNotificationCenter defaultCenter] postItemsChanged:_selection];
    [[[[_core win] libraryViewController] currentViewController] highlightFiles:selection];
}

- (id)valueForAttribute:(PRItemAttr *)attribute {
    if ([_selection count] == 0) {
        return NSNoSelectionMarker;
    }
    id firstResult = [[_db library] valueForItem:[_selection objectAtIndex:0] attr:attribute];
    for (NSNumber *i in _selection) {
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

- (void)toggleCompilation {
    NSNumber *compilation = [self valueForAttribute:PRItemAttrCompilation];
    if (compilation == NSMultipleValuesMarker || [compilation intValue] == 1) {
        [self setValue:@0 forAttribute:PRItemAttrCompilation];
    } else {
        [self setValue:@1 forAttribute:PRItemAttrCompilation];
    }
}

#pragma mark - Misc

- (NSArray *)tagControls {
    static NSMutableArray *array = nil;
    if (!array) {
        array = [[NSMutableArray alloc] init];
        
        NSArray *properties = @[
            @[titleField, PRItemAttrTitle, _stringFormatter, [NSNull null], [NSNull null], @"No Selection", @(STRINGKIND)],
            @[artistField, PRItemAttrArtist, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[albumArtistField, PRItemAttrAlbumArtist, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[albumField, PRItemAttrAlbum, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[yearField, PRItemAttrYear, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[bpmField, PRItemAttrBPM, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[trackField, PRItemAttrTrackNumber, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[trackCountField, PRItemAttrTrackCount, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[discField, PRItemAttrDiscNumber, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[discCountField, PRItemAttrDiscCount, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NUMBERKIND)],
            @[composerField, PRItemAttrComposer, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[commentsField, PRItemAttrComments, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[genreField, PRItemAttrGenre, _stringFormatter, [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[_lyricsField, PRItemAttrLyrics, [NSNull null], [NSNull null], [NSNull null], [NSNull null], @(STRINGKIND)],
            @[_pathField, PRItemAttrPath, _pathFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_kindField, PRItemAttrKind, _kindFormatter, [NSNull null], [NSNull null], @"No Selection", @(NONEKIND)],
            @[_sizeField, PRItemAttrSize, _sizeFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_lastModifiedField, PRItemAttrLastModified, _dateFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_dateAddedField, PRItemAttrDateAdded, _dateFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_lengthField, PRItemAttrTime, _timeFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_bitrateField, PRItemAttrBitrate, _bitrateFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_channelsField, PRItemAttrChannels, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_sampleRateField, PRItemAttrSampleRate, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_playCountField, PRItemAttrPlayCount, _numberFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
            @[_lastPlayedField, PRItemAttrLastPlayed, _dateFormatter, [NSNull null], [NSNull null], [NSNull null], @(NONEKIND)],
        ];
        
        for (NSArray *p in properties) {
            NSString *nullValuePlaceholder = [p objectAtIndex:3];
            if ((id)nullValuePlaceholder == [NSNull null]) {
                nullValuePlaceholder = @"None";
            }
            NSString *multipleValuePlaceholder = [p objectAtIndex:4];
            if ((id)multipleValuePlaceholder == [NSNull null]) {
                multipleValuePlaceholder = @"Multiple Values";
            }
            NSString *noSelectionPlaceholder = [p objectAtIndex:5];
            if ((id)noSelectionPlaceholder == [NSNull null]) {
                noSelectionPlaceholder = @"-";
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:[p objectAtIndex:0] forKey:CONTROLKEY];
            [dict setValue:[p objectAtIndex:1] forKey:ITEMATTRKEY];
            [dict setValue:[p objectAtIndex:2] forKey:FORMATTERKEY];
            [dict setValue:nullValuePlaceholder  forKey:NULLVALUEPLACEHOLDERKEY];
            [dict setValue:multipleValuePlaceholder forKey:MULTIPLEVALUEPLACEHOLDERKEY];
            [dict setValue:noSelectionPlaceholder forKey:NOSELECTIONPLACEHOLDERKEY];
            [dict setValue:[p objectAtIndex:6] forKey:KINDKEY];
            [array addObject:dict];
        }
    }
    return array;
}

@end
