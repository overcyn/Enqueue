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

- (id)initWithCore:(PRCore *)core;

// ========================================
// Update

- (void)updateContent;

@property (readwrite) PRPlaylist playlist;

// ========================================
// Action

- (void)beginSheet;
- (void)endSheet;

@end