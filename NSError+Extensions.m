#import "NSError+Extensions.h"

@implementation NSError (Extensions)

- (NSError *)errorWithLocalizedDescription:(NSString *)description
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self userInfo]];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:[self domain] 
                               code:[self code] 
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

- (NSError *)errorWithLocalizedRecoveryOptions:(NSArray *)recoveryOptions
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self userInfo]];
    [userInfo setValue:recoveryOptions forKey:NSLocalizedRecoveryOptionsErrorKey];
    return [NSError errorWithDomain:[self domain] 
                               code:[self code] 
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

- (NSError *)errorWithLocalizedRecoverySuggestion:(NSString *)recoverySuggestion
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self userInfo]];
    [userInfo setValue:recoverySuggestion forKey:NSLocalizedRecoverySuggestionErrorKey];
    return [NSError errorWithDomain:[self domain] 
                               code:[self code] 
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

- (NSError *)errorWithLocalizedFailureReason:(NSString *)failureReason
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self userInfo]];
    [userInfo setValue:failureReason forKey:NSLocalizedFailureReasonErrorKey];
    return [NSError errorWithDomain:[self domain] 
                               code:[self code] 
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

- (NSError *)errorWithValue:(id)value forKey:(NSString *)key
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[self userInfo]];
    [userInfo setValue:value forKey:key];
    return [NSError errorWithDomain:[self domain] 
                               code:[self code] 
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

@end