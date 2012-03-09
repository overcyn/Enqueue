#import "PRRulePredicateViewController.h"
#import "PRRuleViewController.h"
#import "PRCore.h"
#import "PRGradientView.h"
#import "PRRule.h"
#import "PRLibrary.h"
#import "PRNumberFormatter.h"

@implementation PRRulePredicateViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core ruleView:(PRRuleViewController *)ruleView row:(int)row
{
    if (!(self = [super initWithNibName:@"PRRulePredicateViewController" bundle:nil])) {return nil;}
    _core = core;
    _ruleView = ruleView;
    _row = row;
    return self;
}

- (void)dealloc
{
    [_deleteButton setTarget:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib
{
    [self update];
            
    if (_row == 0) {
        [[self view] addSubview:_predicateView];
        
        // Predicate Menu
        NSString *type = [PRRule typeForAttribute:[_ruleView attribute]];
        NSArray *predicates = [PRRule predicatesForType:type];
        
        NSMenu *menu = [[[NSMenu alloc] init] autorelease];
        for (NSString *i in predicates) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[PRRule stringForPredicate:i] action:@selector(predicateMenuAction:) keyEquivalent:@""];
            [item setRepresentedObject:i];
            [item setTarget:self];
            [menu addItem:item];
        }
        [_predicateButton setMenu:menu];
        [_predicateButton selectItemAtIndex:[_predicateButton indexOfItemWithRepresentedObject:[_ruleView predicate]]];
        
        // Attribute Menu
        menu = [[[NSMenu alloc] init] autorelease];
        NSMutableArray *attributes = [NSMutableArray array];
        for (NSNumber *i in [PRRule attributes]) {
            [attributes addObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [PRLibrary nameForFileAttribute:[i intValue]], @"title", i, @"attribute", nil]];
        }
        [attributes sortUsingComparator:^(id obj1, id obj2) {
            return [(NSString *)[obj1 objectForKey:@"title"] compare:[obj2 objectForKey:@"title"]];
        }];
        for (NSDictionary *i in attributes) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[i objectForKey:@"title"] action:@selector(attributeMenuAction:) keyEquivalent:@""];
            [item setRepresentedObject:[i objectForKey:@"attribute"]];
            [menu addItem:item];
        }
        for (NSMenuItem *i in [menu itemArray]) {
            [i setTarget:self];
        }
        [_fileAttributeButton setMenu:menu];
        [_fileAttributeButton selectItemAtIndex:[_fileAttributeButton indexOfItemWithRepresentedObject:[NSNumber numberWithInt:[_ruleView attribute]]]];
        
        [_addButton setTarget:self];
        [_addButton setAction:@selector(add)];
    }
    
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(delete)];
    
    if ([[_ruleView predicate] isEqualToString:PRPredicateStringIs] ||
        [[_ruleView predicate] isEqualToString:PRPredicateStringIsNot]) {
        [[self view] addSubview:_stringView];        
        [_textField setStringValue:[_ruleView valueForRow:_row]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:_textField];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateNumberIs] ||
               [[_ruleView predicate] isEqualToString:PRPredicateNumberIsNot]) {
        [[self view] addSubview:_stringView];
        [_textField setFormatter:[[PRNumberFormatter alloc] init]];
        [_textField setObjectValue:[_ruleView valueForRow:_row]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:_textField];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateNumberInRange]) {
        [[self view] addSubview:_stringRangeView];        
        [_textField1 setFormatter:[[PRNumberFormatter alloc] init]];
        [_textField2 setFormatter:[[PRNumberFormatter alloc] init]];
        [_textField1 setObjectValue:[[_ruleView valueForRow:_row] objectAtIndex:0]];
        [_textField2 setObjectValue:[[_ruleView valueForRow:_row] objectAtIndex:1]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:_textField1];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:_textField2];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateDateIs] ||
               [[_ruleView predicate] isEqualToString:PRPredicateDateIsNot]) {
        [[self view] addSubview:_dateView];        
        [_dateField setDateValue:[_ruleView valueForRow:_row]];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateDateInRange]) {
        [[self view] addSubview:_dateRangeView];
        [_dateField1 setDateValue:[[_ruleView valueForRow:_row] objectAtIndex:0]];
        [_dateField2 setDateValue:[[_ruleView valueForRow:_row] objectAtIndex:1]];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateDateWithin] ||
               [[_ruleView predicate] isEqualToString:PRPredicateDateNotWithin]) {
        [[self view] addSubview:_dateWithinView];
        
    } else if ([[_ruleView predicate] isEqualToString:PRPredicateBoolIs]) {
        [[self view] addSubview:_boolView];
        
    }
    
    NSArray *subviews = [NSArray arrayWithObjects:_stringView, _stringRangeView, _dateView, _dateRangeView, _dateWithinView, _boolView, nil];
    for (NSView *i in subviews) {
        NSRect frame = [i frame];
        frame.origin.x += 234;
        [i setFrame:frame];
    }
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

- (void)add
{
    id value = nil; 
    NSString *kind = [_ruleView predicate];
    if ([kind isEqualToString:PRPredicateStringIs] ||
        [kind isEqualToString:PRPredicateStringIsNot]) {
        value = @"";
    } else if ([kind isEqualToString:PRPredicateNumberIs] ||
               [kind isEqualToString:PRPredicateNumberIsNot]) {
        value = [NSNumber numberWithInt:0];
    } else if ([kind isEqualToString:PRPredicateNumberInRange]) {
        value = [NSArray arrayWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0], nil];
    } else if ([kind isEqualToString:PRPredicateDateIs] ||
               [kind isEqualToString:PRPredicateDateIsNot]) {
        value = [NSDate date];
    } else if ([kind isEqualToString:PRPredicateDateInRange]) {
        value = [NSArray arrayWithObjects:[NSDate date],[NSDate date], nil];
    } else if ([kind isEqualToString:PRPredicateDateWithin] ||
               [kind isEqualToString:PRPredicateDateNotWithin]) {
        value = @"";
    } else if ([kind isEqualToString:PRPredicateBoolIs]) {
        value = [NSNumber numberWithBool:TRUE];
    }
    [_ruleView addValue:value];
}

- (void)delete
{
    [_ruleView deleteRow:_row];
}
     
- (void)textDidChange:(NSNotificationCenter *)notification
{
    if ([_textField stringValue]) {
        [_ruleView setValue:[_textField stringValue] forRow:_row];
    }
}

- (void)predicateMenuAction:(id)sender
{
    [_ruleView setPredicate:[sender representedObject]];
}

- (void)attributeMenuAction:(id)sender
{
    [_ruleView setAttribute:[[sender representedObject] intValue]];
}

@end
