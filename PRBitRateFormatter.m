//
//  PRBitRateFormatter.m
//  Lyre
//
//  Created by Kevin Dang on 4/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PRBitRateFormatter.h"


@implementation PRBitRateFormatter

- (NSString *)stringForObjectValue:(id)object 
{
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"0 kbps";
    }
    
    return [NSString stringWithFormat:@"%d kbps", [object intValue]];
}

- (BOOL)getObjectValue:(id *)obj 
			 forString:(NSString *)string
	  errorDescription:(NSString **)error 
{
    return NO;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
								 withDefaultAttributes:(NSDictionary *)attributes
{
	return nil;
}

@end
