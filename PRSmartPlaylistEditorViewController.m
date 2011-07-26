#import "PRSmartPlaylistEditorViewController.h"
#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRDb.h"
#import "PRRuleArrayController.h"
#import "PRCore.h"
#import "PRMainWindowController.h"

@implementation PRSmartPlaylistEditorViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(id)core
{
    self = [super initWithWindowNibName:@"PRSmartPlaylistEditorView"];
	if (self) {
        _core = core;
	}
	return self;
}

- (void)awakeFromNib
{
	[matchCheckBox setTarget:self];
	[matchCheckBox setAction:@selector(toggle)];
	[matchCheckBox bind:@"value" 
			   toObject:self 
			withKeyPath:@"currentRule.match" 
				options:nil];
	
	[limitCheckBox setTarget:self];
	[limitCheckBox setAction:@selector(toggle)];
	[limitCheckBox bind:@"value" 
			   toObject:self 
			withKeyPath:@"currentRule.match" 
				options:nil];
	
	[collectionView setMaxNumberOfRows:1];
	[collectionView setItemPrototype:[[PRRuleViewController alloc] initWithLib:[[_core db] library]]];
    [self updateContent];
}

// ========================================
// Accessors
// ========================================

@dynamic playlist;

- (PRPlaylist)playlist
{
    return _playlist;
}

- (void)setPlaylist:(PRPlaylist)playlist
{
    _playlist = playlist;
    [self updateContent];
}

// ========================================
// Update
// ========================================

- (void)updateContent
{
    NSArray *rules = [NSArray arrayWithObject:[NSNumber numberWithInt:0]];
    [collectionView setContent:rules];
}

// ========================================
// Action
// ========================================

- (void)beginSheet
{
    NSLog(@"window:%@ %@",[self window],[[_core win] window]);
	[NSApp beginSheet:[self window]
       modalForWindow:[[_core win] window]
        modalDelegate:self 
	   didEndSelector:nil 
		  contextInfo:nil];
}

- (void)endSheet
{
    [NSApp endSheet:[self window]];
}

@end
