#import <AppKit/AppKit.h>


@interface PRHyperlinkButton : NSButton {
    NSAttributedString *_attrString;
    NSAttributedString *_altAttrString;
    NSTrackingArea *_trackingArea;
}
/* Accessors */
@property (readwrite, retain) NSAttributedString *attrString;
@property (readwrite, retain) NSAttributedString *altAttrString;

/* Misc */
- (NSRect)titleRect;
@end
