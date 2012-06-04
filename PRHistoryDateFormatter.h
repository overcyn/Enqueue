#import <Foundation/Foundation.h>


@interface PRHistoryDateFormatter : NSFormatter {
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_timeFormatter;
}
@end
