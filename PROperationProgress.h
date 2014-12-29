#import <Foundation/Foundation.h>


@interface PROperationProgress : NSObject {
    NSString *_title;
    int _percent;
    BOOL _shouldCancel;
    BOOL _background;
}
/* Initialization */
- (id)init;
+ (PROperationProgress *)task;

/* Accessors */
@property (readwrite, copy) NSString *title;
@property (readwrite) int percent;
@property (readwrite) BOOL shouldCancel;
@property (readwrite) BOOL background;
@end
