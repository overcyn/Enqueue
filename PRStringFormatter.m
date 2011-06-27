//
//  PRLengthFormatter.m
//  Lyre
//
//  Created by Kevin Dang on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PRStringFormatter.h"


@implementation PRStringFormatter

- (id)init
{
    self = [super init];
    if (self) {
        maxLength_ = 255;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize maxLength = maxLength_;

- (NSString *)stringForObjectValue:(id)object 
{
    return (NSString *)object;
}

- (BOOL)getObjectValue:(id *)object 
             forString:(NSString *)string 
      errorDescription:(NSString **)error 
{
    *object = string;
    return TRUE;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error
{
    if ([*partialStringPtr length] > maxLength_) {
        return FALSE;
    }
    return TRUE;
}

@end