#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


@class PRDb, PRGradientView, PRNumberFormatter, PRStringFormatter, PRCore, PRPathFormatter,
PRKindFormatter, PRSizeFormatter, PRDateFormatter, PRTimeFormatter, PRBitRateFormatter;

typedef enum {
    PRInfoModeTags,
    PRInfoModeProperties,
    PRInfoModeLyrics,
    PRInfoModeArtwork,
} PRInfoMode;

@interface PRInfoViewController : NSViewController
{
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
    
    NSArray *controls;
    NSArray *labels;
    PRBitRateFormatter *_bitrateFormatter;
    PRDateFormatter *_dateFormatter;
    PRSizeFormatter *_sizeFormatter;
    PRPathFormatter *_pathFormatter;
    PRKindFormatter *_kindFormatter;
    PRTimeFormatter *_timeFormatter;
    PRNumberFormatter *numberFormatter;
    PRStringFormatter *stringFormatter;
	NSArray *selection;
    
    PRCore *core;
	PRDb *db;
}

// Initialization
- (id)initWithCore:(PRCore *)core_;

// Tab Control
- (void)updateTabControl;
- (NSDictionary *)tabs;
- (void)tabAction:(id)sender;

// Accessors
- (void)update;

- (id)valueForAttribute:(PRFileAttribute)attribute;

- (void)setAlbumArt:(NSImage *)value;
- (NSImage *)albumArt;

- (void)setCompilation:(NSNumber *)value;
- (NSNumber *)compilation;


@end
