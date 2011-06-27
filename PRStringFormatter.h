//
//  PRLengthFormatter.h
//  Lyre
//
//  Created by Kevin Dang on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PRStringFormatter : NSFormatter 
{
    int maxLength_;
}

@property (readwrite) int maxLength;

@end