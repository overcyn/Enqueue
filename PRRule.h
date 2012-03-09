#import <Cocoa/Cocoa.h>

extern NSString * const PRPredicateTypeString;
extern NSString * const PRPredicateTypeNumber;
extern NSString * const PRPredicateTypeDate;
extern NSString * const PRPredicateTypeBool;

extern NSString * const PRPredicateStringIs;
extern NSString * const PRPredicateStringIsNot;
extern NSString * const PRPredicateNumberIs;
extern NSString * const PRPredicateNumberIsNot;
extern NSString * const PRPredicateNumberInRange;
extern NSString * const PRPredicateDateIs;
extern NSString * const PRPredicateDateIsNot;
extern NSString * const PRPredicateDateInRange;
extern NSString * const PRPredicateDateWithin;
extern NSString * const PRPredicateDateNotWithin;
extern NSString * const PRPredicateBoolIs;

@interface PRRule : NSObject <NSCoding>
{

}

- (NSString *)whereStatement;

+ (PRRule *)ruleWithAttribute:(PRFileAttribute)attribute predicate:(NSString *)predicate;
+ (NSArray *)attributes;
+ (NSString *)typeForAttribute:(PRFileAttribute)attribute;
+ (NSArray *)predicatesForType:(NSString *)type;
+ (NSString *)stringForPredicate:(NSString *)predicate;

@end
