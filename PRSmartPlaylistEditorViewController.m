#import "PRSmartPlaylistEditorViewController.h"
#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRDb.h"
#import "PRCore.h"
#import "PRMainWindowController.h"

@implementation PRSmartPlaylistEditorViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core playlist:(PRPlaylist)playlist
{
	if (!(self = [super initWithWindowNibName:@"PRSmartPlaylistEditorView"])) {return nil;}
    _core = core;
    _playlist = playlist;
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
	[collectionView setItemPrototype:[[[PRRuleViewController alloc] initWithLib:[[_core db] library]] autorelease]];
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
