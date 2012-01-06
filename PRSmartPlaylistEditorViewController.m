#import "PRSmartPlaylistEditorViewController.h"
#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRDb.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRRuleCompound.h"

@implementation PRSmartPlaylistEditorViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core playlist:(PRPlaylist)playlist
{
	if (!(self = [super initWithWindowNibName:@"PRSmartPlaylistEditorView"])) {return nil;}
    _core = core;
    _playlist = playlist;
    _datasource = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [_datasource release];
}

- (void)awakeFromNib
{
    [_OKButton setTarget:self];
    [_OKButton setAction:@selector(endSheet)];
    
    [_cancelButton setTarget:self];
    [_cancelButton setAction:@selector(endSheet)];
    
//	[matchCheckBox setTarget:self];
//	[matchCheckBox setAction:@selector(toggle)];
//	
//	[limitCheckBox setTarget:self];
//	[limitCheckBox setAction:@selector(toggle)];
	
    [collectionView setContent:_datasource];
	[collectionView setMaxNumberOfRows:1];
	[collectionView setItemPrototype:[[[PRRuleViewController alloc] init] autorelease]];
    [self updateContent];
}

// ========================================
// Update
// ========================================

- (void)updateContent
{
    NSData *data = [[[_core db] playlists] valueForPlaylist:_playlist attribute:PRRulesPlaylistAttribute];
    NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    PRRuleCompound *rule = [dictionary objectForKey:@"compound"];
    [collectionView setContent:[rule subRules]];
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

- (void)replaceRule:(PRRule *)oldRule withRule:(PRRule *)newRule
{
    
}

- (void)deleteRule:(PRRule *)rule
{
    
}

@end
