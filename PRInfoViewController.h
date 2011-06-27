#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


@class PRDb, PRTagEditor, PRGradientView, PRNumberFormatter, PRStringFormatter, PRCore;

@interface PRInfoViewController : NSViewController
{	
	IBOutlet NSTextField *path;
	IBOutlet NSTextField *kind;
	IBOutlet NSTextField *size;
	IBOutlet NSTextField *bitRate;
	IBOutlet NSTextField *sampleRate;
	IBOutlet NSTextField *time;
	IBOutlet NSTextField *format;
	IBOutlet NSTextField *channels;
	IBOutlet NSTextField *ID3Tag;
	IBOutlet NSTextField *dateAdded;
	IBOutlet NSTextField *lastPlayed;
	IBOutlet NSTextField *playCount;
	
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
	
    IBOutlet NSSegmentedControl *ratingControl;
    IBOutlet NSImageView *albumArtView;
    
    IBOutlet PRGradientView *gradientView;
    
    
    PRNumberFormatter *numberFormatter;
    PRStringFormatter *stringFormatter;
	NSArray *selection;
    
    PRCore *core;
	PRDb *db;
}


- (id)initWithCore:(PRCore *)core_;
- (void)update;
- (id)valueForAttribute:(PRFileAttribute)attribute;
- (void)tagsDidChange:(NSNotification *)notification;
- (void)libraryViewSelectionDidChange:(NSNotification *)notification;

@end