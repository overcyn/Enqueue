#import "PRSmartPlaylistEditorViewController.h"
#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRRuleArrayController.h"


@implementation PRSmartPlaylistEditorViewController

// initialization

- (id)initWithDb:(PRDb *)db
{
	if (self = [super initWithNibName:@"PRSmartPlaylistEditorView" bundle:nil]) {
		lib = [db library];
		play = [db playlists];
		
		subRuleArrayController = [[PRRuleArrayController alloc] init];
		prototypeRuleViewController = [[PRRuleViewController alloc] initWithLib:lib];
		
		// subRuleArrayController
		[subRuleArrayController bind:@"contentArray" toObject:self withKeyPath:@"currentRule.subRules" options:nil];
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
	[collectionView bind:@"content" toObject:subRuleArrayController withKeyPath:@"arrangedObjects" options:nil];
	[collectionView setItemPrototype:prototypeRuleViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(addRuleNotification:) 
												 name:PRAddRuleNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(deleteRuleNotification:) 
												 name:PRDeleteRuleNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(ruleDidChangeNotification:) 
												 name:PRRuleDidChangeNotification 
											   object:nil];
}

// accessors

- (PRRule *)currentRule
{
	return currentRule;
}

- (void)setCurrentRule:(PRRule *)newRule
{
	currentRule = newRule;
	[self didChangeValueForKey:@"currentRule"];
}

- (void)setCurrentPlaylist:(PRPlaylist)newCurrentPlaylist
{
	currentPlaylist = newCurrentPlaylist;
	[self updateCurrentRule];
}

// update

- (void)updateCurrentRule
{
	NSData *data;
	PRRule *rule;
	
	[play value:&data 
	forPlaylist:currentPlaylist 
	  attribute:PRRulesPlaylistAttribute 
		 _error:nil];

	if (!data) {
		rule = [[PRRule alloc] init];
	} else {
		rule = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	[self setCurrentRule:rule];
}

- (void)saveCurrentRule
{
	NSData *data;
	
	data = [NSKeyedArchiver archivedDataWithRootObject:currentRule];
	[play setValue:data 
	   forPlaylist:currentPlaylist 
		 attribute:PRRulesPlaylistAttribute 
			_error:nil];
}

- (void)ruleDidChangeNotification:(NSNotification *)notification
{
	[self saveCurrentRule];
}

- (void)deleteRuleNotification:(NSNotification *)notification
{
	NSDictionary *userInfo;
	
	userInfo = [notification userInfo];
	[self removeSubRule:[userInfo valueForKey:@"rule"]];
}

- (void)addRuleNotification:(NSNotification *)notification
{
	[self addSubRule];
}

// action

- (void)addSubRule
{
	[subRuleArrayController addObject:[[[PRRule alloc] init] autorelease]];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRuleDidChangeNotification 
														object:self 
													  userInfo:nil];
	[self saveCurrentRule];
}

- (void)removeSubRule:(PRRule *)subRule
{
	[subRuleArrayController removeObject:subRule];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRuleDidChangeNotification 
														object:self 
													  userInfo:nil];
	[self saveCurrentRule];
}

- (void)toggle
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRuleDidChangeNotification 
														object:self 
													  userInfo:nil];
	[self saveCurrentRule];
}

@end
