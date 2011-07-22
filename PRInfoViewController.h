#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


@class PRDb, PRTagEditor, PRGradientView, PRNumberFormatter, PRStringFormatter, PRCore;

@interface PRInfoViewController : NSViewController
{	
    IBOutlet NSTextField *titleLabel;
	IBOutlet NSTextField *artistLabel;	
	IBOutlet NSTextField *albumArtistLabel;	
	IBOutlet NSTextField *albumLabel;
	IBOutlet NSTextField *yearLabel;
	IBOutlet NSTextField *bpmLabel;	
	IBOutlet NSTextField *trackLabel;	
	IBOutlet NSTextField *trackCountLabel;		
	IBOutlet NSTextField *discLabel;
	IBOutlet NSTextField *discCountLabel;
	IBOutlet NSTextField *composerLabel;	
	IBOutlet NSTextField *commentsLabel;
	IBOutlet NSTextField *genreLabel;

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
    
    IBOutlet NSTextField *NoSelection;
    
    NSArray *controls;
    NSArray *labels;
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