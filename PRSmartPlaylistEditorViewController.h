#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"


@class PRDb;
@class PRRule;
@class PRRuleViewController;
@class PRLibrary;
@class PRPlaylists;
@class PRRuleArrayController;

@interface PRSmartPlaylistEditorViewController : NSViewController
{
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSButton *matchCheckBox;
	IBOutlet NSButton *limitCheckBox;
	
	PRRuleArrayController *subRuleArrayController;
	PRRuleViewController *prototypeRuleViewController;
	
	PRPlaylist currentPlaylist;
	PRRule *currentRule;
	
	PRLibrary *lib;
	PRPlaylists *play;
}

// initialization
- (id)initWithDb:(PRDb *)db_;

// accessors
- (void)setCurrentPlaylist:(PRPlaylist)newCurrentPlaylist;

- (PRRule *)currentRule;
- (void)setCurrentRule:(PRRule *)newRule;

// update
- (void)updateCurrentRule;
- (void)saveCurrentRule;
- (void)ruleDidChangeNotification:(NSNotification *)notification;
- (void)addRuleNotification:(NSNotification *)notification;
- (void)deleteRuleNotification:(NSNotification *)notification;

// action
- (void)addSubRule;
- (void)removeSubRule:(PRRule *)subRule;
- (void)toggle;

@end