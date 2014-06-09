#import <Foundation/Foundation.h>


@interface PRStringFormatter : NSFormatter {
    int _maxLength;
}

@property (readwrite) int maxLength;

@end