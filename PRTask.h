#import <Foundation/Foundation.h>


@interface PRTask : NSObject 
{
    NSString *title;
    NSNumber *value;
    BOOL shouldCancel;
    BOOL background;
}

@property (readwrite, retain) NSString *title;
@property (readwrite, retain) NSNumber *value;
@property (readwrite) BOOL shouldCancel;
@property (readwrite) BOOL background;

@end
