#import <AppKit/AppKit.h>


@interface PRHyperlinkButton : NSButton {
    NSAttributedString *_attrString;
    NSAttributedString *_altAttrString;
    NSTrackingArea *_trackingArea;
}
/* Accessors */
@property (readwrite, strong) NSAttributedString *attrString;
@property (readwrite, strong) NSAttributedString *altAttrString;

/* Misc */
- (NSRect)titleRect;
@end
