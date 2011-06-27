#import "PRNonScrollingScrollView.h"


@implementation PRNonScrollingScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
	void (*responderScroll)(id, SEL, id);
	
	responderScroll = (void (*)(id, SEL, id))([NSResponder instanceMethodForSelector:@selector(scrollWheel:)]);
	responderScroll(self, @selector(scrollWheel:), theEvent);
}

@end
