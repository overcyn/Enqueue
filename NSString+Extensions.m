//
//  NSString+Extensions.m
//  Lyre
//
//  Created by Kevin Dang on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (NSString_Extensions)

+ (NSString *)stringWithNumber:(NSNumber *)number
{
    return [NSString stringWithFormat:@"%@",number];
}

+ (NSString *)stringWithInt:(int)integer
{
    return [NSString stringWithFormat:@"%d",integer];
}

@end
