#import "PRRule.h"
#import "PRRuleCompound.h"
#import "PRRulePredicate.h"
#import "PRRuleStringIs.h"
#import "PRRuleStringIsNot.h"
#import "PRRuleNumberIs.h"
#import "PRRuleNumberIsNot.h"
#import "PRRuleNumberInRange.h"
#import "PRRuleDateIs.h"
#import "PRRuleDateIsNot.h"
#import "PRRuleDateInRange.h"
#import "PRRuleDateWithin.h"
#import "PRRuleDateNotWithin.h"
#import "PRRuleBoolIs.h"


NSString * const PRPredicateTypeString = @"PRPredicateTypeString";
NSString * const PRPredicateTypeNumber = @"PRPredicateTypeNumber";
NSString * const PRPredicateTypeDate = @"PRPredicateTypeDate";
NSString * const PRPredicateTypeBool = @"PRPredicateTypeBool";

NSString * const PRPredicateStringIs = @"PRPredicateStringIs";
NSString * const PRPredicateStringIsNot = @"PRPredicateStringIsNot";
NSString * const PRPredicateNumberIs = @"PRPredicateNumberIs";
NSString * const PRPredicateNumberIsNot = @"PRPredicateNumberIsNot";
NSString * const PRPredicateNumberInRange = @"PRPredicateNumberInRange";
NSString * const PRPredicateDateIs = @"PRPredicateDateIs";
NSString * const PRPredicateDateIsNot = @"PRPredicateDateIsNot";
NSString * const PRPredicateDateInRange = @"PRPredicateDateInRange";
NSString * const PRPredicateDateWithin = @"PRPredicateDateWithin";
NSString * const PRPredicateDateNotWithin = @"PRPredicateDateNotWithin";
NSString * const PRPredicateBoolIs = @"PRPredicateBoolIs";


@implementation PRRule

- (void)encodeWithCoder:(NSCoder *)coder
{
	
}

- (id)initWithCoder:(NSCoder *)coder
{
    return nil;
}

- (NSString *)whereStatement
{
    return nil;
}

+ (PRRule *)ruleWithAttribute:(PRFileAttribute)attribute predicate:(NSString *)predicate
{
    NSArray *predicates = [PRRule predicatesForType:[PRRule typeForAttribute:attribute]];
    if (![predicates containsObject:predicate]) {
        predicate = [predicates objectAtIndex:0];
    }
    
    PRRulePredicate *rule;
    if ([predicate isEqualToString:PRPredicateStringIs]) {
        rule = [[[PRRuleStringIs alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateStringIsNot]) {
        rule = [[[PRRuleStringIsNot alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateNumberIs]) {
        rule = [[[PRRuleNumberIs alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateNumberIsNot]) {
        rule = [[[PRRuleNumberIsNot alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateNumberInRange]) {
        rule = [[[PRRuleNumberInRange alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateDateIs]) {
        rule = [[[PRRuleDateIs alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateDateIsNot]) {
        rule = [[[PRRuleDateIsNot alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateDateInRange]) {
        rule = [[[PRRuleDateInRange alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateDateWithin]) {
        rule = [[[PRRuleDateWithin alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateDateNotWithin]) {
        rule = [[[PRRuleDateNotWithin alloc] init] autorelease];
    } else if ([predicate isEqualToString:PRPredicateBoolIs]) {
        rule = [[[PRRuleBoolIs alloc] init] autorelease];
    }
    [rule setFileAttribute:attribute];
    return rule;
}

+ (NSArray *)attributes
{
    return [[NSDictionary dictionaryWithObjectsAndKeys:
             PRPredicateTypeString, [NSNumber numberWithInt:PRTitleFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRArtistFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRAlbumFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRComposerFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRCommentsFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
             PRPredicateTypeString, [NSNumber numberWithInt:PRGenreFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRLyricsFileAttribute], 
             PRPredicateTypeString, [NSNumber numberWithInt:PRTitleFileAttribute], 
             
             PRPredicateTypeString, [NSNumber numberWithInt:PRPathFileAttribute], 
             
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRBPMFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRYearFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRTrackNumberFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRTrackCountFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRDiscNumberFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRDiscCountFileAttribute], 
             
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRSizeFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRTimeFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRBitrateFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRChannelsFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRSampleRateFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRPlayCountFileAttribute], 
             PRPredicateTypeNumber, [NSNumber numberWithInt:PRRatingFileAttribute], 
             
             PRPredicateTypeDate, [NSNumber numberWithInt:PRLastModifiedFileAttribute], 
             PRPredicateTypeDate, [NSNumber numberWithInt:PRDateAddedFileAttribute], 
             PRPredicateTypeDate, [NSNumber numberWithInt:PRLastPlayedFileAttribute], 
             
             PRPredicateTypeBool, [NSNumber numberWithInt:PRCompilationFileAttribute], 
             nil] allKeys];
}

+ (NSString *)typeForAttribute:(PRFileAttribute)attribute
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          PRPredicateTypeString, [NSNumber numberWithInt:PRTitleFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRArtistFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRAlbumFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRComposerFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRCommentsFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                          PRPredicateTypeString, [NSNumber numberWithInt:PRGenreFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRLyricsFileAttribute], 
                          PRPredicateTypeString, [NSNumber numberWithInt:PRTitleFileAttribute], 
                          
                          PRPredicateTypeString, [NSNumber numberWithInt:PRPathFileAttribute], 
                          
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRBPMFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRYearFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRTrackNumberFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRTrackCountFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRDiscNumberFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRDiscCountFileAttribute], 
                          
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRSizeFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRTimeFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRBitrateFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRChannelsFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRSampleRateFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRPlayCountFileAttribute], 
                          PRPredicateTypeNumber, [NSNumber numberWithInt:PRRatingFileAttribute], 
                          
                          PRPredicateTypeDate, [NSNumber numberWithInt:PRLastModifiedFileAttribute], 
                          PRPredicateTypeDate, [NSNumber numberWithInt:PRDateAddedFileAttribute], 
                          PRPredicateTypeDate, [NSNumber numberWithInt:PRLastPlayedFileAttribute], 
                          
                          PRPredicateTypeBool, [NSNumber numberWithInt:PRCompilationFileAttribute], 
                          nil];
    return [dict objectForKey:[NSNumber numberWithInt:attribute]];
}

+ (NSArray *)predicatesForType:(NSString *)type
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSArray arrayWithObjects:
                           PRPredicateStringIs, 
                           PRPredicateStringIsNot, nil], 
                          PRPredicateTypeString,
                          [NSArray arrayWithObjects:
                           PRPredicateNumberIs, 
                           PRPredicateNumberIsNot,
                           PRPredicateNumberInRange, nil],
                          PRPredicateTypeNumber,
                          [NSArray arrayWithObjects:
                           PRPredicateDateIs,
                           PRPredicateDateIsNot,
                           PRPredicateDateInRange,
                           PRPredicateDateWithin,
                           PRPredicateDateNotWithin, nil],
                          PRPredicateTypeDate,
                          [NSArray arrayWithObjects:
                           PRPredicateBoolIs, nil],
                          PRPredicateTypeBool,
                          nil];
    return [dict objectForKey:type];
}

+ (NSString *)stringForPredicate:(NSString *)predicate
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"is", PRPredicateStringIs,
                          @"is not", PRPredicateStringIsNot,
                          @"is", PRPredicateNumberIs,
                          @"is not", PRPredicateNumberIsNot,
                          @"in range", PRPredicateNumberInRange,
                          @"is", PRPredicateDateIs,
                          @"is not", PRPredicateDateIsNot,
                          @"in range", PRPredicateDateInRange,
                          @"in last", PRPredicateDateWithin,
                          @"not in last", PRPredicateDateNotWithin,
                          @"is", PRPredicateBoolIs, nil];
    return [dict objectForKey:predicate];
}

@end
