#import "PRInfoViewController.h"
#import "PRLibraryViewController.h"
#import "PRLibrary.h"
#import "PRAlbumArtController.h"
#import "PRDb.h"
#import "PRRatingCell.h"
#import "PRGradientView.h"
#import "PRNumberFormatter.h"
#import "PRStringFormatter.h"
#import "NSIndexSet+Extensions.h"
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


@implementation PRInfoViewController

- (id)initWithCore:(PRCore *)core_ {
	if (!(self = [super initWithNibName:@"PRInfoView" bundle:nil])) {return nil;}
    core = [core_ retain];
    db = [[core db] retain];
    numberFormatter = [[PRNumberFormatter alloc] init];
    stringFormatter = [[PRStringFormatter alloc] init];
    _pathFormatter = [[PRPathFormatter alloc] init];
    _kindFormatter = [[PRKindFormatter alloc] init];
    _sizeFormatter = [[PRSizeFormatter alloc] init];
    _dateFormatter = [[PRDateFormatter alloc] init];
    _timeFormatter = [[PRTimeFormatter alloc] init];
    _bitrateFormatter = [[PRBitRateFormatter alloc] init];
    _mode = PRInfoModeTags;
    
    [[NSNotificationCenter defaultCenter] observeLibraryViewSelectionChanged:self sel:@selector(update)];
    [[NSNotificationCenter defaultCenter] observeFilesChanged:self sel:@selector(update)];
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [numberFormatter release];
    [stringFormatter release];
    [_pathFormatter release];
    [_kindFormatter release];
    [db release];
    [super dealloc];
}

- (void)awakeFromNib {	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"-", NSNoSelectionPlaceholderBindingOption,
                             @"None", NSNullPlaceholderBindingOption,
                             nil];
    
    NSDictionary *options2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"-", NSNoSelectionPlaceholderBindingOption,
                              @"Mul...", NSMultipleValuesPlaceholderBindingOption,
                              @"None", NSNullPlaceholderBindingOption,
                              nil];
    NSDictionary *options3 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"None", NSNullPlaceholderBindingOption, nil];
    
	[titleField bind:@"value" toObject:self withKeyPath:@"title" options:options3];
	[artistField bind:@"value" toObject:self withKeyPath:@"artist" options:options];
	[albumArtistField bind:@"value" toObject:self withKeyPath:@"albumArtist" options:options];
	[albumField bind:@"value" toObject:self withKeyPath:@"album" options:options];
	[yearField bind:@"value" toObject:self withKeyPath:@"year" options:options2];
	[bpmField bind:@"value" toObject:self withKeyPath:@"bpm" options:options2];
	[trackField bind:@"value" toObject:self withKeyPath:@"track" options:options2];
	[trackCountField bind:@"value" toObject:self withKeyPath:@"trackCount" options:options2];
	[discField bind:@"value" toObject:self withKeyPath:@"disc" options:options2];
	[discCountField bind:@"value" toObject:self withKeyPath:@"discCount" options:options2];
	[composerField bind:@"value" toObject:self withKeyPath:@"composer" options:options];
	[commentsField bind:@"value" toObject:self withKeyPath:@"comments" options:options];
	[genreField bind:@"value" toObject:self withKeyPath:@"genre" options:options];
//    [albumArtView bind:@"value" toObject:self withKeyPath:@"albumArt" options:nil];
	
	[titleField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[artistField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[albumArtistField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[albumField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[yearField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[bpmField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[trackField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[trackCountField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[discField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[discCountField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[composerField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[commentsField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
	[genreField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
    [albumArtView bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
    [ratingControl bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
    
    [_pathField bind:@"value" toObject:self withKeyPath:@"path" options:options];
    [_kindField bind:@"value" toObject:self withKeyPath:@"kind" options:options3];
    [_sizeField bind:@"value" toObject:self withKeyPath:@"size" options:options];
    [_lastModifiedField bind:@"value" toObject:self withKeyPath:@"lastModified" options:options];
    [_dateAddedField bind:@"value" toObject:self withKeyPath:@"dateAdded" options:options];
    [_lengthField bind:@"value" toObject:self withKeyPath:@"length" options:options];
    [_bitrateField bind:@"value" toObject:self withKeyPath:@"bitrate" options:options];
    [_channelsField bind:@"value" toObject:self withKeyPath:@"channels" options:options];
    [_sampleRateField bind:@"value" toObject:self withKeyPath:@"sampleRate" options:options];
    [_playCountField bind:@"value" toObject:self withKeyPath:@"playCount" options:options];
    [_lastPlayedField bind:@"value" toObject:self withKeyPath:@"lastPlayed" options:options];
    
    [_lyricsField bind:@"value" toObject:self withKeyPath:@"lyrics" options:options3];
    [_lyricsField bind:@"enabled" toObject:self withKeyPath:@"enabled" options:nil];
    
    [albumArtView addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    [[ratingControl cell] addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    
    [_compilationButton setTarget:self];
    [_compilationButton setAction:@selector(toggleCompilation)];
    
    controls = [[NSArray arrayWithObjects:
                 titleField,
                 artistField,
                 albumArtistField,
                 albumField,
                 yearField,
                 bpmField,
                 trackField,
                 trackCountField,
                 discField,
                 discCountField,
                 composerField,
                 commentsField,
                 genreField,
                 albumArtView,
                 ratingControl, 
                 _lyricsField, nil] retain];
        
    [titleField setFormatter:stringFormatter];
    [artistField setFormatter:stringFormatter];
    [albumArtistField setFormatter:stringFormatter];
    [albumField setFormatter:stringFormatter];
    [yearField setFormatter:numberFormatter];
    [bpmField setFormatter:numberFormatter];
    [trackField setFormatter:numberFormatter];
    [trackCountField setFormatter:numberFormatter];
    [discField setFormatter:numberFormatter];
    [discCountField setFormatter:numberFormatter];
    [composerField setFormatter:stringFormatter];
    [commentsField setFormatter:stringFormatter];
    [genreField setFormatter:stringFormatter];
    
    [_pathField setFormatter:_pathFormatter];
    [_kindField setFormatter:_kindFormatter];
    [_sizeField setFormatter:_sizeFormatter];
    [_lastModifiedField setFormatter:_dateFormatter];
    [_dateAddedField setFormatter:_dateFormatter];
    [_lengthField setFormatter:_timeFormatter];
    [_bitrateField setFormatter:_bitrateFormatter];
    [_lastPlayedField setFormatter:_dateFormatter];
    
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
           [[db library] setValue:[NSNumber numberWithInt:rating] forItem:i attr:PRItemAttrRating];
       }
       [[NSNotificationCenter defaultCenter] postFilesChanged:[NSIndexSet indexSetWithArray:selection]];
   } else if (object == albumArtView && [keyPath isEqualToString:@"objectValue"]) {
       [self setAlbumArt:[object objectValue]];
   }
}

- (void)toggleCompilation {
    NSNumber *compilation = [self compilation];
    if (compilation == NSMultipleValuesMarker || [compilation intValue] == 1) {
        [self setCompilation:[NSNumber numberWithInt:0]];
    } else {
        [self setCompilation:[NSNumber numberWithInt:1]];
    }
}

- (void)update {
    [selection release];
	selection = [[[[[core win] libraryViewController] currentViewController] selection] retain];
    
    [ratingControl setHidden:([selection count] == 0)];
    
    [self willChangeValueForKey:@"enabled"];
    [self didChangeValueForKey:@"enabled"];
    
    [self willChangeValueForKey:@"title"];
	[self didChangeValueForKey:@"title"];
	[self willChangeValueForKey:@"artist"];
	[self didChangeValueForKey:@"artist"];
	[self willChangeValueForKey:@"albumArtist"];
	[self didChangeValueForKey:@"albumArtist"];
	[self willChangeValueForKey:@"album"];
	[self didChangeValueForKey:@"album"];
	[self willChangeValueForKey:@"year"];
	[self didChangeValueForKey:@"year"];
	[self willChangeValueForKey:@"bpm"];
	[self didChangeValueForKey:@"bpm"];
	[self willChangeValueForKey:@"track"];
	[self didChangeValueForKey:@"track"];
	[self willChangeValueForKey:@"trackCount"];
	[self didChangeValueForKey:@"trackCount"];
	[self willChangeValueForKey:@"disc"];
	[self didChangeValueForKey:@"disc"];
	[self willChangeValueForKey:@"discCount"];
	[self didChangeValueForKey:@"discCount"];
	[self willChangeValueForKey:@"composer"];
	[self didChangeValueForKey:@"composer"];
	[self willChangeValueForKey:@"comments"];
	[self didChangeValueForKey:@"comments"];
	[self willChangeValueForKey:@"genre"];
	[self didChangeValueForKey:@"genre"];    
    [self willChangeValueForKey:@"albumArt"];
	[self didChangeValueForKey:@"albumArt"];
    [self willChangeValueForKey:@"rating"];
    [self didChangeValueForKey:@"rating"];
    
    [self willChangeValueForKey:@"path"];
	[self didChangeValueForKey:@"path"];
    [self willChangeValueForKey:@"kind"];
	[self didChangeValueForKey:@"kind"];
    [self willChangeValueForKey:@"size"];
	[self didChangeValueForKey:@"size"];
    [self willChangeValueForKey:@"lastModified"];
	[self didChangeValueForKey:@"lastModified"];
    [self willChangeValueForKey:@"dateAdded"];
	[self didChangeValueForKey:@"dateAdded"];
    [self willChangeValueForKey:@"length"];
	[self didChangeValueForKey:@"length"];
    [self willChangeValueForKey:@"channels"];
    [self didChangeValueForKey:@"channels"];
    [self willChangeValueForKey:@"bitrate"];
    [self didChangeValueForKey:@"bitrate"];
    [self willChangeValueForKey:@"sampleRate"];
	[self didChangeValueForKey:@"sampleRate"];
    [self willChangeValueForKey:@"playCount"];
	[self didChangeValueForKey:@"playCount"];
    [self willChangeValueForKey:@"lastPlayed"];
	[self didChangeValueForKey:@"lastPlayed"];
    
    [self willChangeValueForKey:@"lyrics"];
    [self didChangeValueForKey:@"lyrics"];
    
    [albumArtView setImage:[self albumArt]];
    NSNumber *rating = [self valueForAttribute:PRRatingFileAttribute];
    if ([rating isKindOfClass:[NSNumber class]]) {
        [ratingControl setSelectedSegment:floor([rating intValue] / 20)];
    } else {
        [ratingControl setSelectedSegment:0];
    }
    
    NSNumber *compilation = [self compilation];
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
// Accessors

- (BOOL)enabled {
	return [selection count] != 0;
}

- (void)setValue:(id)value forAttribute:(PRFileAttribute)attribute {
    if ([selection count] == 0) {
		return;
	}
    
    for (NSControl *control in controls) {
        if ([control isKindOfClass:[NSTextField class]]) {
            [control cancelOperation:nil];
        }
    }
    
    for (NSNumber *i in selection) {
        [PRTagger setTag:value forAttribute:attribute URL:[[db library] URLForItem:i]];
        [[db library] updateTagsForItem:i];
    }
    
    NSIndexSet *selectionIndexes = [NSIndexSet indexSetWithArray:selection];
    [[NSNotificationCenter defaultCenter] postFilesChanged:selectionIndexes];
    [[[[core win] libraryViewController] currentViewController] highlightFiles:selectionIndexes];
    [[NSOperationQueue mainQueue] addBlock:^{[self update];}];
}

- (id)valueForAttribute:(PRFileAttribute)attribute {	
	if ([selection count] == 0) {
		return NSNoSelectionMarker;
	}
    
    id firstResult = [[db library] valueForItem:[selection objectAtIndex:0] attr:[PRLibrary itemAttrForInternal:[NSNumber numberWithInt:attribute]]];
    for (NSNumber *i in selection) {
        id result = [[db library] valueForItem:i attr:[PRLibrary itemAttrForInternal:[NSNumber numberWithInt:attribute]]];
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

- (void)setTitle:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRTitleFileAttribute];
}

- (NSString *)title {
	return [self valueForAttribute:PRTitleFileAttribute];
}

- (void)setArtist:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRArtistFileAttribute];
}

- (NSString *)artist {
	return [self valueForAttribute:PRArtistFileAttribute];
}

- (void)setAlbumArtist:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRAlbumArtistFileAttribute];
}

- (NSString *)albumArtist {
	return [self valueForAttribute:PRAlbumArtistFileAttribute];
}

- (void)setAlbum:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRAlbumFileAttribute];
}

- (NSString *)album {
	return [self valueForAttribute:PRAlbumFileAttribute];
}

- (void)setYear:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRYearFileAttribute];
}

- (NSNumber *)year {
	return [self valueForAttribute:PRYearFileAttribute];
}

- (void)setBpm:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRBPMFileAttribute];
}

- (NSNumber *)bpm {
	return [self valueForAttribute:PRBPMFileAttribute];
}

- (void)setTrack:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRTrackNumberFileAttribute];
}

- (NSNumber *)track {
	return [self valueForAttribute:PRTrackNumberFileAttribute];
}

- (void)setTrackCount:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRTrackCountFileAttribute];
}

- (NSNumber *)trackCount {
	return [self valueForAttribute:PRTrackCountFileAttribute];
}

- (void)setDisc:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRDiscNumberFileAttribute];
}

- (NSNumber *)disc {
	return [self valueForAttribute:PRDiscNumberFileAttribute];
}

- (void)setDiscCount:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRDiscCountFileAttribute];
}

- (NSNumber *)discCount {
	return [self valueForAttribute:PRDiscCountFileAttribute];
}

- (void)setComposer:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRComposerFileAttribute];
}

- (NSString *)composer {
	return [self valueForAttribute:PRComposerFileAttribute];
}

- (void)setComments:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRCommentsFileAttribute];
}

- (NSString *)comments {
	return [self valueForAttribute:PRCommentsFileAttribute];
}

- (void)setGenre:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRGenreFileAttribute];
}

- (NSString *)genre {
	return [self valueForAttribute:PRGenreFileAttribute];
}

- (void)setAlbumArt:(NSImage *)value {
    NSData *data = [value TIFFRepresentation];
    if (!value) {
        data = [NSData data];
    }
    [self setValue:data forAttribute:PRAlbumArtFileAttribute];
}

- (NSImage *)albumArt {
    if ([selection count] == 0) {
        return nil;
    }
    
    PRFile file = [[selection objectAtIndex:0] intValue];
    NSImage *albumArt = [[db albumArtController] cachedArtForFile:file];
    return albumArt;
}

- (void)setCompilation:(NSNumber *)value {
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRCompilationFileAttribute];
}

- (NSNumber *)compilation {
    return [self valueForAttribute:PRCompilationFileAttribute];
}

- (void)setLyrics:(NSString *)value {
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRLyricsFileAttribute];
}

- (NSString *)lyrics {
    return [self valueForAttribute:PRLyricsFileAttribute];
}

- (NSString *)path {
    return [self valueForAttribute:PRPathFileAttribute];
}

- (NSNumber *)kind {
    return [self valueForAttribute:PRKindFileAttribute];
}

- (NSNumber *)size {
    return [self valueForAttribute:PRSizeFileAttribute];
}

- (NSNumber *)lastModified {
    return [self valueForAttribute:PRLastModifiedFileAttribute];
}

- (NSNumber *)dateAdded {
    return [self valueForAttribute:PRDateAddedFileAttribute];
}

- (NSNumber *)length {
    return [self valueForAttribute:PRTimeFileAttribute];
}

- (NSNumber *)bitrate {
    return [self valueForAttribute:PRBitrateFileAttribute];
}

- (NSNumber *)channels {
    return [self valueForAttribute:PRChannelsFileAttribute];
}

- (NSNumber *)sampleRate {
    return [self valueForAttribute:PRSampleRateFileAttribute];
}

- (NSNumber *)playCount {
    return [self valueForAttribute:PRPlayCountFileAttribute];
}

- (NSNumber *)lastPlayed {
    return [self valueForAttribute:PRLastPlayedFileAttribute];
}

@end
