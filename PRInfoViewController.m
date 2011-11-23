#import "PRInfoViewController.h"
#import "PRLibraryViewController.h"
#import "PRLibrary.h"
#import "PRAlbumArtController.h"
#import "PRDb.h"
#import "PRTagEditor.h"
#import "PRRatingCell.h"
#import "PRGradientView.h"
#import "PRNumberFormatter.h"
#import "PRStringFormatter.h"
#import "NSIndexSet+Extensions.h"
#import "PRCore.h"
#import "PRTableViewController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"

@implementation PRInfoViewController

- (id)initWithCore:(PRCore *)core_
{
	if (!(self = [super initWithNibName:@"PRInfoView" bundle:nil])) {return nil;}
    core = [core_ retain];
    db = [[core db] retain];
    numberFormatter = [[PRNumberFormatter alloc] init];
    stringFormatter = [[PRStringFormatter alloc] init];
    
    [[NSNotificationCenter defaultCenter] observeLibraryViewSelectionChanged:self sel:@selector(update)];
    [[NSNotificationCenter defaultCenter] observeFilesChanged:self sel:@selector(update)];
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [db release];
    [super dealloc];
}

- (void)awakeFromNib
{	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"-", NSNoSelectionPlaceholderBindingOption,
                             @"None", NSNullPlaceholderBindingOption,
                             nil];
    
    NSDictionary *options2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"-", NSNoSelectionPlaceholderBindingOption,
                              @"Mul...", NSMultipleValuesPlaceholderBindingOption,
                              @"None", NSNullPlaceholderBindingOption,
                              nil];
    
	[titleField bind:@"value" toObject:self withKeyPath:@"title" options:nil];
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
    
    [albumArtView addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    [[ratingControl cell] addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
    
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
                 ratingControl, nil] retain];
    labels = [[NSArray arrayWithObjects:
               titleLabel,
               artistLabel,
               albumArtistLabel,
               albumLabel,
               yearLabel,
               bpmLabel,
               trackLabel,
               trackCountLabel,
               discLabel,
               discCountLabel,
               composerLabel,
               commentsLabel,
               genreLabel,
               ratingLabel, nil] retain];
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
    [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont systemFontOfSize:30.0], NSFontAttributeName,
                                       shadow, NSShadowAttributeName,
                                       [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], NSForegroundColorAttributeName, nil];
    NSAttributedString *s = [[[NSAttributedString alloc] initWithString:@"No Selection" attributes:attributes] autorelease];
    [NoSelection setAttributedStringValue:s];
    
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
    
    [gradientView setTopBorder:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
    [gradientView setTopGradient:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    [gradientView setBotGradient:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    
    // rating
    [((PRRatingCell *)[ratingControl cell]) setShowDots:TRUE];
    
    [self update];
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
   if (object == [ratingControl cell] && [keyPath isEqualToString:@"objectValue"]) {
       if ([selection count] == 0) {
           return;
       }
       int rating = [ratingControl selectedSegment] * 20;
       for (NSNumber *i in selection) {
           [[db library] setValue:[NSNumber numberWithInt:rating] forFile:[i intValue] attribute:PRRatingFileAttribute];
       }
       [[NSNotificationCenter defaultCenter] postFilesChanged:[NSIndexSet indexSetWithArray:selection]];
   } else if (object == albumArtView && [keyPath isEqualToString:@"objectValue"]) {
       [self setAlbumArt:[object objectValue]];
   }
}

- (void)update
{
    [selection release];
	selection = [[[[[core win] libraryViewController] currentViewController] selection] retain];
    
    [NoSelection setHidden:([selection count] != 0)];
    for (id i in controls) {
        [i setHidden:![selection count]];
    }
    for (id i in labels) {
        [i setHidden:![selection count]];
    }
    
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
    
    [albumArtView setImage:[self albumArt]];
    NSNumber *rating = [self valueForAttribute:PRRatingFileAttribute];
    if ([rating isKindOfClass:[NSNumber class]]) {
        [ratingControl setSelectedSegment:floor([rating intValue] / 20)];
    } else {
        [ratingControl setSelectedSegment:0];
    }
}

// ========================================
// Accessors
// ========================================

- (BOOL)enabled
{
	return [selection count] != 0;
}

- (void)setValue:(id)value forAttribute:(PRFileAttribute)attribute
{
    if ([selection count] == 0) {
		return;
	}
    
    for (NSControl *control in controls) {
        if ([control isKindOfClass:[NSTextField class]]) {
            [control cancelOperation:nil];
        }
    }
    
    for (NSNumber *i in selection) {
        PRTagEditor *te = [PRTagEditor tagEditorForURL:[[db library] URLforFile:[i intValue]]];
        [te setValue:value forTag:attribute];
        [[db library] updateTagsForFile:[i intValue]];
    }
    
    NSIndexSet *selectionIndexes = [NSIndexSet indexSetWithArray:selection];
    [[NSNotificationCenter defaultCenter] postFilesChanged:selectionIndexes];
    [[[[core win] libraryViewController] currentViewController] highlightFiles:selectionIndexes];
    [[NSOperationQueue mainQueue] addBlock:^{[self update];}];
}

- (id)valueForAttribute:(PRFileAttribute)attribute
{	
	if ([selection count] == 0) {
		return NSNoSelectionMarker;
	}
    
    id firstResult = [[db library] valueForFile:[[selection objectAtIndex:0] intValue] attribute:attribute];
    for (NSNumber *i in selection) {
        id result = [[db library] valueForFile:[i intValue] attribute:attribute];
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

- (void)setTitle:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRTitleFileAttribute];
}

- (NSString *)title
{
	return [self valueForAttribute:PRTitleFileAttribute];
}

- (void)setArtist:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRArtistFileAttribute];
}

- (NSString *)artist
{
	return [self valueForAttribute:PRArtistFileAttribute];
}

- (void)setAlbumArtist:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRAlbumArtistFileAttribute];
}

- (NSString *)albumArtist
{
	return [self valueForAttribute:PRAlbumArtistFileAttribute];
}

- (void)setAlbum:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRAlbumFileAttribute];
}

- (NSString *)album
{
	return [self valueForAttribute:PRAlbumFileAttribute];
}

- (void)setYear:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRYearFileAttribute];
}

- (NSNumber *)year
{
	return [self valueForAttribute:PRYearFileAttribute];
}

- (void)setBpm:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRBPMFileAttribute];
}

- (NSNumber *)bpm
{
	return [self valueForAttribute:PRBPMFileAttribute];
}

- (void)setTrack:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRTrackNumberFileAttribute];
}

- (NSNumber *)track
{
	return [self valueForAttribute:PRTrackNumberFileAttribute];
}

- (void)setTrackCount:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRTrackCountFileAttribute];
}

- (NSNumber *)trackCount
{
	return [self valueForAttribute:PRTrackCountFileAttribute];
}

- (void)setDisc:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRDiscNumberFileAttribute];
}

- (NSNumber *)disc
{
	return [self valueForAttribute:PRDiscNumberFileAttribute];
}

- (void)setDiscCount:(NSNumber *)value
{
    if (!value) {
        value = [NSNumber numberWithInt:0];
    }
    [self setValue:value forAttribute:PRDiscCountFileAttribute];
}

- (NSNumber *)discCount
{
	return [self valueForAttribute:PRDiscCountFileAttribute];
}

- (void)setComposer:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRComposerFileAttribute];
}

- (NSString *)composer
{
	return [self valueForAttribute:PRComposerFileAttribute];
}

- (void)setComments:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRCommentsFileAttribute];
}

- (NSString *)comments
{
	return [self valueForAttribute:PRCommentsFileAttribute];
}

- (void)setGenre:(NSString *)value
{
    if (!value) {
        value = @"";
    }
    [self setValue:value forAttribute:PRGenreFileAttribute];
}

- (NSString *)genre
{
	return [self valueForAttribute:PRGenreFileAttribute];
}

- (void)setAlbumArt:(NSImage *)value
{
    NSData *data = [value TIFFRepresentation];
    if (!value) {
        data = [NSData data];
    }
    [self setValue:data forAttribute:PRAlbumArtFileAttribute];
}

- (NSImage *)albumArt
{
    if ([selection count] == 0) {
        return nil;
    }
    
    PRFile file = [[selection objectAtIndex:0] intValue];
    NSImage *albumArt = [[db albumArtController] cachedArtForFile:file];
    return albumArt;
}

@end
