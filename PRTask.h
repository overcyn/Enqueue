#import <Foundation/Foundation.h>


@interface PRTask : NSObject 
{
    NSString *title;
    NSNumber *value;
    BOOL shouldCancel;
    BOOL background;
}

- (id)init;
+ (PRTask *)task;

@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSNumber *value;
@property (readwrite) BOOL shouldCancel;
@property (readwrite) BOOL background;

@end
