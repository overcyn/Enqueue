//
//  NSError+Extensions.h
//  Lyre
//
//  Created by Kevin Dang on 3/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSError (Extensions)

- (NSError *)errorWithLocalizedDescription:(NSString *)description;
- (NSError *)errorWithLocalizedRecoveryOptions:(NSArray *)recoveryOptions;
- (NSError *)errorWithLocalizedRecoverySuggestion:(NSString *)recoverySuggestion;
- (NSError *)errorWithLocalizedFailureReason:(NSString *)failureReason;
- (NSError *)errorWithValue:(id)value forKey:(NSString *)key;

@end