#import "PRRuleViewController.h"
#import "PRLibrary.h"
#import "PRRule.h"
#import "PRRulePredicate.h"
#import "PRCore.h"
#import "PRSmartPlaylistEditorViewController.h"
#import "PRRulePredicateViewController.h"

@implementation PRRuleViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core editor:(PRSmartPlaylistEditorViewController *)editor
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    _editor = editor;
    _predicateViews = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [_predicateViews release];
    [super dealloc];
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
    _predicateViews = [[NSMutableArray alloc] init];
}

- (void)awakeFromNib
{
    [self update];
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
    for (PRRulePredicateViewController *i in _predicateViews) {
        [[i view] removeFromSuperview];
    }
    [_predicateViews removeAllObjects];
    
    for (NSView *i in [_contentView  subviews]) {
        [i removeFromSuperview];
    }
    
    float contentHeight = 10;
    int row = 0;
    for (NSDictionary *i in [(PRRulePredicate *)[self representedObject] values]) {
        PRRulePredicateViewController *predicate = [[[PRRulePredicateViewController alloc] initWithCore:_core ruleView:self row:row] autorelease];
        [_predicateViews addObject:predicate];
        [_contentView addSubview:[predicate view]];
        NSRect frame = [[predicate view] frame];
        frame.origin.x = 10;
        frame.origin.y = contentHeight;
        [[predicate view] setFrame:frame];
        contentHeight += 30;
        row++;
    }
    
    NSRect frame = [_contentView frame];
    frame.size.height = contentHeight;
    [_contentView setFrame:frame];
}

// ========================================
// Action
// ========================================

- (void)addValue:(id)value
{
    [[(PRRulePredicate *)[self representedObject] values] addObject:value];
    [self update];
}

- (void)deleteRow:(int)row
{
    if ([[(PRRulePredicate *)[self representedObject] values] count] == 1) {
        [_editor deleteRule:[self representedObject]];
        return;
    }
    [[(PRRulePredicate *)[self representedObject] values] removeObjectAtIndex:row];
    [self update];
}

- (void)setValue:(id)value forRow:(int)row
{
    [[(PRRulePredicate *)[self representedObject] values] replaceObjectAtIndex:row withObject:value];
}

- (id)valueForRow:(int)row
{
    return [[(PRRulePredicate *)[self representedObject] values] objectAtIndex:row];
}

- (NSString *)predicate
{
    return [[(PRRulePredicate *)[self representedObject] class] predicate];
}

- (PRFileAttribute)attribute
{
    return [(PRRulePredicate *)[self representedObject] fileAttribute];
}

- (void)setPredicate:(NSString *)predicate
{
    [_editor replaceRule:(PRRulePredicate *)[self representedObject] withRule:[PRRule ruleWithAttribute:[self attribute] predicate:predicate]];
}

- (void)setAttribute:(PRFileAttribute)attribute
{
    PRRule *rule = [PRRulePredicate ruleWithAttribute:attribute predicate:[self predicate]];
    [_editor replaceRule:(PRRulePredicate *)[self representedObject] withRule:rule];
}

- (float)height
{
    return [[[self representedObject] values] count] * 30;
}

@end
