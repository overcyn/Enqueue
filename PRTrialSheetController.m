#import "PRTrialSheetController.h"


@interface PRTrialSheetController ()
// action
- (void)ignore;
- (void)purchase;
@end


@implementation PRTrialSheetController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super initWithWindowNibName:@"PRTrialSheet"])) {return nil;}
    _core = core;
    _date = [[NSDate dateWithString:@"2012-02-20 01:00:00 +0000"] retain];
    return self;
}

- (void)awakeFromNib {
    NSDictionary *regularAttr = [NSDictionary dictionary];
    NSDictionary *boldAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont boldSystemFontOfSize:13], NSFontAttributeName, 
                              [[NSColor redColor] blendedColorWithFraction:0.3 ofColor:[NSColor blackColor]], NSForegroundColorAttributeName, nil];
    
    int days = [_date timeIntervalSinceNow] / (60 * 60 * 24);
    NSString *daysString = [NSString stringWithFormat:@"%d",days];
    
    NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:@"This release will stop working in " attributes:regularAttr] autorelease];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:daysString attributes:boldAttr] autorelease]];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@" days." attributes:regularAttr] autorelease]];
    
    [ignore setTitle:@"Ignore"];
    if ([_date timeIntervalSinceNow] < 0) {
        [ignore setTitle:@"Quit"];
    }
    
    [label setAttributedStringValue:string];
    if ([_date timeIntervalSinceNow] < 0) {
        [label setStringValue:@"This beta release has expired."];
    }
    
    [purchase setTarget:self];
    [purchase setAction:@selector(purchase)];
    [ignore setTarget:self];
    [ignore setAction:@selector(ignore)];
    [super awakeFromNib];
}

// ========================================
// action

- (void)purchase {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/enqueue/id493119959?ls=1&mt=12"]];
    [self endSheet];
}

- (void)ignore {
    if ([_date timeIntervalSinceNow] < 0) {
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0];
    }
    [self endSheet];
}

// ========================================
// Sheet

- (void)beginSheetForWindow:(NSWindow *)window {
    [NSApp beginSheet:[self window] 
       modalForWindow:window 
        modalDelegate:self 
       didEndSelector:NULL
          contextInfo:nil];
}

- (void)endSheet{
    [[self window] orderOut:nil];
    [NSApp endSheet:[self window]];
}

@end
