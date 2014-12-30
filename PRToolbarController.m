#import "PRToolbarController.h"

#define SIDEBAR_ID      @"1"
#define INFO_ID         @"2"
#define SEARCH_ID       @"3"
#define SEGMENTED_ID    @"4"
#define BUTTON_WIDTH    40
#define SEARCH_WIDTH    200

@interface PRToolbarController () <NSToolbarDelegate>
@end

@implementation PRToolbarController {
    id<PRToolbarControllerDelegate> _delegate;
    NSToolbar *_toolbar;
    NSSegmentedControl *_segmentedControl;
    NSButton *_sidebarButton;
    NSButton *_infoButton;
    NSSearchField *_searchField;
}

- (id)init {
    if ((self = [super init])) {
        _toolbar = [[NSToolbar alloc] initWithIdentifier:@""];
        [_toolbar setDelegate:self];
        
        _segmentedControl = [[NSSegmentedControl alloc] init];
        [_segmentedControl setSegmentCount:4];
        [_segmentedControl setLabel:@"Library" forSegment:0];
        [_segmentedControl setLabel:@"Playlists" forSegment:1];
        [_segmentedControl setLabel:@"History" forSegment:2];
        [_segmentedControl setLabel:@"Preferences" forSegment:3];
        [_segmentedControl setAction:@selector(_segmentedControlAction:)];
        [_segmentedControl setTarget:self];
        
        _sidebarButton = [[NSButton alloc] init];
        [_sidebarButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [_sidebarButton setButtonType:NSMomentaryLightButton];
        [_sidebarButton setImage:[NSImage imageNamed:@"sidebar"]];
        [_sidebarButton setAction:@selector(_sidebarButtonAction:)];
        [_sidebarButton setTarget:self];
        
        _infoButton = [[NSButton alloc] init];
        [_infoButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [_infoButton setButtonType:NSMomentaryLightButton];
        [_infoButton setImage:[NSImage imageNamed:@"info"]];
        [_infoButton setTarget:self];
        [_infoButton setAction:@selector(_infoButtonAction:)];
        
        _searchField = [[NSSearchField alloc] init];
        [_searchField setBezeled:YES];
        [_searchField setBezelStyle:NSTextFieldSquareBezel];
    }
    return self;
}

#pragma mark - API

@synthesize delegate = _delegate;

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = nil;
    if ([identifier isEqualToString:SEGMENTED_ID]) {
        [_segmentedControl sizeToFit];
        item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
        [item setView:_segmentedControl];
        [item setMinSize:[_segmentedControl frame].size];
        [item setMaxSize:[_segmentedControl frame].size];
    } else if ([identifier isEqualToString:SIDEBAR_ID]) {
        [_sidebarButton sizeToFit];
        CGSize size = [_sidebarButton frame].size;
        size.width = BUTTON_WIDTH;
        item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
        [item setView:_sidebarButton];
        [item setMinSize:size];
        [item setMaxSize:size];
    } else if ([identifier isEqualToString:INFO_ID]) {
        [_infoButton sizeToFit];
        CGSize size = [_infoButton frame].size;
        size.width = BUTTON_WIDTH;
        item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
        [item setView:_infoButton];
        [item setMinSize:size];
        [item setMaxSize:size];
    } else if ([identifier isEqualToString:SEARCH_ID]) {
        [_searchField sizeToFit];
        CGSize size = [_searchField frame].size;
        size.width = SEARCH_WIDTH;
        item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
        [item setView:_searchField];
        [item setMinSize:size];
        [item setMaxSize:size];
    }
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[SIDEBAR_ID, INFO_ID, SEGMENTED_ID, NSToolbarFlexibleSpaceItemIdentifier, SEARCH_ID];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[SIDEBAR_ID, INFO_ID, NSToolbarFlexibleSpaceItemIdentifier, SEGMENTED_ID, NSToolbarFlexibleSpaceItemIdentifier, SEARCH_ID];
}

#pragma mark - Action

- (void)_sidebarButtonAction:(id)sender {
    [_delegate toolbarControllerSidebarButtonPressed:self];
}

- (void)_infoButtonAction:(id)sender {
    [_delegate toolbarControllerInfoButtonPressed:self];
}

- (void)_segmentedControlAction:(id)sender {
    [_delegate toolbarControllerSelectedSegmentChanged:self];
}

@end
