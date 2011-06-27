#import <Foundation/Foundation.h>


@interface PRScrollView : NSScrollView 
{
    NSSize minimumSize;
}

@property (readwrite) NSSize minimumSize;

- (void)viewFrameDidChange:(NSNotification *)notification;

@end