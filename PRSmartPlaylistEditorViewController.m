#import "PRSmartPlaylistEditorViewController.h"
#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRRuleCompound.h"
#import "PRRuleLimit.h"

@implementation PRSmartPlaylistEditorViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core playlist:(PRPlaylist)playlist
{
	if (!(self = [super initWithWindowNibName:@"PRSmartPlaylistEditorView"])) {return nil;}
    _core = core;
    _playlist = playlist;
//    _datasource = [[[[_core db] playlists] ruleForPlaylist:_playlist] retain];
	return self;
}

- (void)dealloc
{
    [_datasource release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [[self window] setMinSize:NSMakeSize(570, 400)];
    [[self window] setMaxSize:NSMakeSize(570, 10000)];
    
    [_OKButton setTarget:self];
    [_OKButton setAction:@selector(endSheet)];
    
    [_cancelButton setTarget:self];
    [_cancelButton setAction:@selector(endSheet)];
    
    [_addButton setTarget:self];
    [_addButton setAction:@selector(add)];
    
	[matchCheckBox setTarget:self];
	[matchCheckBox setAction:@selector(toggle)];
	
	[limitCheckBox setTarget:self];
	[limitCheckBox setAction:@selector(toggle)];
    
    [self update];
}

// ========================================
// Update
// ========================================

- (void)update
{
    
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

- (void)add
{
    [[[_datasource objectForKey:@"compound"] subRules] addObject:[PRRule ruleWithAttribute:PRArtistFileAttribute predicate:PRPredicateStringIs]];
    [self update];
}

- (void)replaceRule:(PRRule *)oldRule withRule:(PRRule *)newRule
{
    int index = [[[_datasource objectForKey:@"compound"] subRules] indexOfObject:oldRule];
    [[[_datasource objectForKey:@"compound"] subRules] replaceObjectAtIndex:index withObject:newRule];
    [self update];
}

- (void)deleteRule:(PRRule *)rule
{
    [[[_datasource objectForKey:@"compound"] subRules] removeObject:rule];
    [self update];
}

@end
