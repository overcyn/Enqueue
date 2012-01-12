#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRRule.h"

@class PRCore, PRSmartPlaylistEditorViewController, PRGradientView;

@interface PRRuleViewController : NSCollectionViewItem
{
    IBOutlet NSScrollView *_scrollView;
	IBOutlet NSView *_contentView;
    
    NSMutableArray *_predicateViews;
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

- (void)addValue:(id)value;
- (void)deleteRow:(int)row;
- (void)setValue:(id)value forRow:(int)row;
- (id)valueForRow:(int)row;
- (NSString *)predicate;
- (void)setPredicate:(NSString *)predicate;
- (PRFileAttribute)attribute;
- (void)setAttribute:(PRFileAttribute)attribute;

- (float)height;

@end
