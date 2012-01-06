#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRRulePredicate.h"
#import "PRCore.h"
#import "PRSmartPlaylistEditorViewController.h"

@implementation PRRuleViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core editor:(PRSmartPlaylistEditorViewController *)editor
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    _editor = editor;
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	id result = [super copyWithZone:zone];
	[NSBundle loadNibNamed:@"PRRuleView" owner:result];
	[result setCore:_core editor:_editor];
	return result;
}

- (void)setCore:(PRCore *)core editor:(PRSmartPlaylistEditorViewController *)editor
{
    _core = core;
    _editor = editor;
}

- (void)awakeFromNib
{
    [_tableView setDataSource:self];
    [_addButton setTarget:self];
    [_addButton setAction:@selector(add)];
}

// ========================================
// Update
// ========================================

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    [self update];
}

- (void)update
{
    
}

// ========================================
// Action
// ========================================

- (void)attributeMenuAction:(id)sender
{
    PRFileAttribute attribute;
    int predicate;
    PRRule *rule = [PRRulePredicate ruleWithAttribute:attribute predicate:predicate];
    [_editor replaceRule:[self representedObject] withRule:rule];
}

- (void)predicateMenuAction:(id)sender
{
    PRFileAttribute attribute;
    int predicate;
	PRRule *rule = [PRRulePredicate ruleWithAttribute:attribute predicate:predicate];
    [_editor replaceRule:[self representedObject] withRule:rule];
}

- (void)add
{
    
}

- (void)deleteRow:(int)row
{
    
}

// ========================================
// TableView Data Source
// ========================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if ([[tableColumn identifier] isEqualToString:@"value"]) {
		return [array objectAtIndex:rowIndex];
	} else {
		BOOL checkBoxState = [[[self representedObject] selectedObjects] containsObject:[array objectAtIndex:rowIndex]];
		return [NSNumber numberWithBool:checkBoxState];
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object_ forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
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
	
}

@end
