#import <AppKit/AppKit.h>

@interface PRHyperlinkButton : NSButton
{
    NSAttributedString *_attrString;
    NSAttributedString *_altAttrString;
    NSTrackingArea *_trackingArea;
}

@property (readwrite, retain) NSAttributedString *attrString;
@property (readwrite, retain) NSAttributedString *altAttrString;

- (NSRect)titleRect;

@end
