#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"


@class PRDb, PRCore, PRRule, PRRuleViewController, PRRuleArrayController;

@interface PRSmartPlaylistEditorViewController : NSWindowController
{
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSButton *matchCheckBox;
	IBOutlet NSButton *limitCheckBox;
	
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

@end