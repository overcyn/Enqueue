#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"


@class PRDb, PRCore, PRRule, PRRuleViewController, PRRuleArrayController;

@interface PRSmartPlaylistEditorViewController : NSWindowController
{
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSButton *matchCheckBox;
	IBOutlet NSButton *limitCheckBox;
    IBOutlet NSButton *_addButton;
	IBOutlet NSButton *_OKButton;
    IBOutlet NSButton *_cancelButton;
    
    NSMutableArray *_datasource;
	PRPlaylist _playlist;
	
    PRCore *_core;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core playlist:(PRPlaylist)playlist;

// ========================================
// Update

- (void)updateContent;

// ========================================
// Action

- (void)beginSheet;
- (void)endSheet;

- (void)replaceRule:(PRRule *)oldRule withRule:(PRRule *)newRule;
- (void)deleteRule:(PRRule *)rule;

@end