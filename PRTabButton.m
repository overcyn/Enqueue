//
//  PRTabButton.m
//  Lyre
//
//  Created by Kevin Dang on 10/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PRTabButton.h"

@implementation PRTabButton

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self state] != NSOnState) {
        [super mouseDown:theEvent];
    }
}

@end
