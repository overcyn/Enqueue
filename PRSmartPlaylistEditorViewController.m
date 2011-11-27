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

- (id)initWithCore:(PRCore *)core
{
	if (!(self = [super initWithWindowNibName:@"PRSmartPlaylistEditorView"])) {return nil;}
    _core = core;
    _playlist = 0;
    _datasource = [[NSMutableArray alloc] init];
	return self;
}

- (void)awakeFromNib
{
    [_OKButton setTarget:self];
    [_OKButton setAction:@selector(endSheet)];
    
    [_cancelButton setTarget:self];
    [_cancelButton setAction:@selector(endSheet)];
    
	[matchCheckBox setTarget:self];
	[matchCheckBox setAction:@selector(toggle)];
//	[matchCheckBox bind:@"value" 
//			   toObject:self 
//			withKeyPath:@"currentRule.match" 
//				options:nil];
	
	[limitCheckBox setTarget:self];
	[limitCheckBox setAction:@selector(toggle)];
//	[limitCheckBox bind:@"value" 
//			   toObject:self 
//			withKeyPath:@"currentRule.match" 
//				options:nil];
	
    [collectionView setContent:_datasource];
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
    [[self window] orderOut:nil];
    [NSApp endSheet:[self window]];
}

@end
