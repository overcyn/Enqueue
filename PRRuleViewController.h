#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRRule.h"

@class PRCore, PRSmartPlaylistEditorViewController;

@interface PRRuleViewController : NSCollectionViewItem <NSTableViewDataSource>
{
    IBOutlet NSTableView *_tableView;
    IBOutlet NSButton *_addButton;
    IBOutlet NSPopUpButton *_attributeButton;
    IBOutlet NSPopUpButton *_predicateButton;
	
	PRCore *_core;
    PRSmartPlaylistEditorViewController *_editor;
}

// ========================================
// Initializaiton

- (id)initWithCore:(PRCore *)core editor:(PRSmartPlaylistEditorViewController *)editor;
- (void)setCore:(PRCore *)core editor:(PRSmartPlaylistEditorViewController *)editor;

// ========================================
// Update

- (void)update;

// ========================================
// Action

- (void)attributeMenuAction:(id)sender;
- (void)predicateMenuAction:(id)sender;
- (void)deleteRow:(int)row;
- (void)add;

@end
