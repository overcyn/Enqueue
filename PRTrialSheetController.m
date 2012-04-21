#import "PRTrialSheetController.h"


@interface PRTrialSheetController ()
/* action */
- (void)ignore;
- (void)purchase;
/* misc */
+ (NSDate *)date;
@end


@implementation PRTrialSheetController

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    [self loadWindow];
    return self;
}

- (void)loadWindow {
    if (_didLoadWindow) {
        return;
    }
    _didLoadWindow = TRUE;
    
    // Window
    NSWindow *window = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 320, 165) 
                                                  styleMask:NSTitledWindowMask 
                                                    backing:NSBackingStoreBuffered 
                                                      defer:YES 
                                                     screen:nil];
    [self setWindow:window];
    
    
    // Buttons
    NSString *ignoreString;
    if ([[[self class] date] timeIntervalSinceNow] < 0) {
        ignoreString = @"Quit";
        [_label setStringValue:@"This trial has expired."];
    } else {
        ignoreString = @"Ignore";
    }
    _purchase = [[NSButton alloc] initWithFrame:NSMakeRect(160, 17, 100, 32)];
    [_purchase setTarget:self];
    [_purchase setAction:@selector(purchase)];
    [_purchase setBezelStyle:NSRoundedBezelStyle];
    [_purchase setTitle:@"Purchase"];
    [[window contentView] addSubview:_purchase];
    [window setDefaultButtonCell:[_purchase cell]];
    
    _ignore = [[NSButton alloc] initWithFrame:NSMakeRect(60, 17, 100, 32)];
    [_ignore setTarget:self];
    [_ignore setAction:@selector(ignore)];
    [_ignore setBezelStyle:NSRoundedBezelStyle];
    [_ignore setTitle:ignoreString];
    [_ignore setKeyEquivalent:@"\E"];
    [[window contentView] addSubview:_ignore];
    [window setInitialFirstResponder:_ignore];
    
    _label = [[NSTextField alloc] initWithFrame:NSMakeRect(27, 50, 266, 98)];
    [_label setEditable:FALSE];
    [_label setDrawsBackground:FALSE];
    [_label setBordered:FALSE];
    [[window contentView] addSubview:_label];
    
    NSDictionary *regularAttr = [NSDictionary dictionary];
    NSDictionary *shortAttr = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:5], NSFontAttributeName, nil];
    NSDictionary *boldAttr = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
    NSDictionary *boldRedAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont boldSystemFontOfSize:13], NSFontAttributeName, 
                              [[NSColor redColor] blendedColorWithFraction:0.3 ofColor:[NSColor blackColor]], NSForegroundColorAttributeName, nil];
    
    int days = [[[self class] date] timeIntervalSinceNow] / (60 * 60 * 24);
    NSString *daysString = [NSString stringWithFormat:@"%d",days];
    
    NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@"30 Day Trial" attributes:boldAttr] autorelease]];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n" attributes:shortAttr] autorelease]];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@"Enqueue is now available for purchase in the Mac App Store. \n\nThis release will stop working in " attributes:regularAttr] autorelease]];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:daysString attributes:boldRedAttr] autorelease]];
    [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@" days." attributes:regularAttr] autorelease]];
    [_label setAttributedStringValue:string];
}

#pragma mark - action

- (void)purchase {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/enqueue/id493119959?ls=1&mt=12"]];
    [self endSheet];
}

- (void)ignore {
    if ([[[self class] date] timeIntervalSinceNow] < 0) {
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0];
    }
    [self endSheet];
}

#pragma mark - misc

+ (NSDate *)date {
    return [NSDate dateWithString:@"2012-04-25 01:00:00 +0000"];
}

@end
