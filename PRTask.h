#import <Foundation/Foundation.h>


@interface PRTask : NSObject 
{
    NSString *title;
    int percent;
    BOOL shouldCancel;
    BOOL background;
}

- (id)init;
+ (PRTask *)task;

@property (readwrite, copy) NSString *title;
@property (readwrite) int percent;
@property (readwrite) BOOL shouldCancel;
@property (readwrite) BOOL background;

@end
