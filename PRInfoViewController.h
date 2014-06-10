#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRViewController.h"

@class PRDb;
@class PRGradientView;
@class PRNumberFormatter;
@class PRStringFormatter;
@class PRCore;
@class PRPathFormatter;
@class PRKindFormatter;
@class PRSizeFormatter;
@class PRDateFormatter;
@class PRTimeFormatter;
@class PRBitRateFormatter;


typedef enum {
    PRInfoModeTags,
    PRInfoModeProperties,
    PRInfoModeLyrics,
    PRInfoModeArtwork,
} PRInfoMode;


@interface PRInfoViewController : PRViewController
/* Initialization */
- (id)initWithCore:(PRCore *)core;
@end
