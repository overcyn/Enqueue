#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"


NSString * const PRAddRuleNotification = @"PRAddRuleNotification";
NSString * const PRDeleteRuleNotification = @"PRDeleteRuleNotification";
NSString * const PRRuleDidChangeNotification = @"PRRuleDidChangeNotification";

@implementation PRRuleViewController

// initialization

- (id)initWithLib:(PRLibrary *)lib_
{
    self = [super init];
	if (self) {
		lib = lib_;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	id result = [super copyWithZone:zone];
	[NSBundle loadNibNamed:@"PRRuleView" owner:result];
	[result setLib:lib];
	return result;
}

// accessors

- (void)setLib:(PRLibrary *)newLib
{
	lib = newLib;
}

- (void)setRepresentedObject:(id)representedObject
{
	if (representedObject == nil) {
		return;
	}
	
	if (representedObject == [NSNumber numberWithInt:0]) {
		[addButton setTarget:self];
		[addButton setAction:@selector(add)];
		[popUpButton setHidden:TRUE];
		[closeButton setHidden:TRUE];
		[textField setHidden:TRUE];
		[box setContentView:addView];
		return;
	}
	
	[box setContentView:listView];
	[super setRepresentedObject:representedObject];
	array = [[NSArray alloc] init];

	// delete button
	[closeButton setTarget:self];
	[closeButton setAction:@selector(delete)];
	
	// tableview
	[tableView setDataSource:self];
	
	// popup button menu
	menu = [popUpButton menu];
	
	NSMenuItem *menuItem;
	SEL menuAction = @selector(menuAction:);
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Artist" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRArtistFileAttribute];
	[menu addItem:menuItem];
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Album" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRAlbumFileAttribute];
	[menu addItem:menuItem];
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"BPM" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRBPMFileAttribute];
	[menu addItem:menuItem];
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Year" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRYearFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Track Number" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRTrackNumberFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Track Count" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRTrackCountFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Composer" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRComposerFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Disc Number" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRDiscNumberFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Disc Count" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRDiscCountFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Album Artist" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRAlbumArtistFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Genre" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRGenreFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Date Added" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRDateAddedFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Last Played" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRLastPlayedFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Play Count" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRPlayCountFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Rating" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRRatingFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Size" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRSizeFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Kind" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRKindFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Time" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRTimeFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Bitrate" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRBitrateFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Channels" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRChannelsFileAttribute];
	[menu addItem:menuItem];	
	menuItem = [[[NSMenuItem alloc] initWithTitle:@"Sample Rate" action:menuAction keyEquivalent:@""] autorelease];
	[menuItem setTag:PRSampleRateFileAttribute];
	[menu addItem:menuItem];	
	
	for (NSMenuItem *i in [menu itemArray]) {
		[i setTarget:self];
	}
	
	[popUpButton selectItemWithTag:[[self representedObject] fileAttribute]];
	[self update];
}

// Update

- (void)update
{
//	[lib arrayOfUniqueValues:&array forAttribute:[[self representedObject] fileAttribute] _error:nil];
	[tableView reloadData];
}

// Action

- (void)menuAction:(id)sender
{
	[[self representedObject] setFileAttribute:[sender tag]];
	[(PRRule *) [self representedObject] setSelectedObjects:[[[NSMutableArray alloc] init] autorelease]];
	[self update];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRuleDidChangeNotification 
														object:self 
													  userInfo:nil];
}

- (void)delete
{
	NSDictionary *userInfo;
	
	userInfo = [NSDictionary dictionaryWithObject:[self representedObject] forKey:@"rule"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRDeleteRuleNotification 
														object:self 
													  userInfo:userInfo];
}

- (void)add
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PRAddRuleNotification 
														object:self 
													  userInfo:nil];
}

// NSTableView Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [array count];
}

- (id)            tableView:(NSTableView *)tableView 
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
			            row:(NSInteger)rowIndex
{
	if ([[tableColumn identifier] isEqualToString:@"value"]) {
		return [array objectAtIndex:rowIndex];
	} else {
		BOOL checkBoxState;
		
		checkBoxState = [[[self representedObject] selectedObjects] containsObject:[array objectAtIndex:rowIndex]];
		
		return [NSNumber numberWithBool:checkBoxState];
	}

	
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)object_
   forTableColumn:(NSTableColumn *)tableColumn 
			  row:(NSInteger)rowIndex
{
	id object;
	NSMutableArray *selectedObjects;
	
	object = [array objectAtIndex:rowIndex];
	selectedObjects = [(PRRule *) [self representedObject] selectedObjects];
	
	if ([selectedObjects containsObject:object]) {
		[selectedObjects removeObject:object];
	} else {
		[selectedObjects addObject:object];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRuleDidChangeNotification 
														object:self 
													  userInfo:nil];
}

@end
