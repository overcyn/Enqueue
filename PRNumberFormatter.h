/*
 PRNumberFormatter.h
 
 PRNumberFormatter is a subclass of NSNumberFormatter. It only allows numeric characters and 
 has maximum length of 4. Zeros are displayed as empty strings.
 */

#import <Cocoa/Cocoa.h>


@interface PRNumberFormatter : NSNumberFormatter 
{

}

@end