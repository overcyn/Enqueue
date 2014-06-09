#import "PREQ.h"


@implementation PREQ

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    _title = @"";
    _amplitudes = @[@0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0];
    return self;
}

+ (PREQ *)EQ {
    return [[PREQ alloc] init];
}

+ (PREQ *)EQWithEQ:(PREQ *)EQ_ {
    PREQ *EQ = [PREQ EQ];
    [EQ setTitle:[EQ_ title]];
    [EQ setAmplitudes:[EQ_ amplitudes]];
    return EQ;
}


#pragma mark - Accessors

@synthesize title = _title, 
amplitudes = _amplitudes;

- (void)setAmp:(float)amp forFreq:(PREQFreq)freq {
    NSMutableArray *a = [NSMutableArray arrayWithArray:_amplitudes];
    [a replaceObjectAtIndex:freq withObject:[NSNumber numberWithFloat:amp]];
    _amplitudes = [NSArray arrayWithArray:a];
}

- (float)ampForFreq:(PREQFreq)freq {
    return [[_amplitudes objectAtIndex:freq] floatValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"PREQ:%@ %@",_title,[_amplitudes class]];
}

#pragma mark - DefaultEQs

+ (NSArray *)defaultEQs {
    return [NSArray arrayWithObjects:[PREQ flat],[PREQ stairs], [PREQ triangle], nil];
}

+ (PREQ *)flat {
    PREQ *flat = [PREQ EQ];
    [flat setTitle:@"Flat"];
    return flat;
}

+ (PREQ *)stairs {
    PREQ *stairs = [PREQ EQ];
    [stairs setTitle:@"Stairs"];
    [stairs setAmplitudes:@[@0, @-10, @-10, @-5, @-5, @0, @0, @5, @5, @10, @10]];
    return stairs;
}

+ (PREQ *)triangle {
    PREQ *stairs = [PREQ EQ];
    [stairs setTitle:@"Triangle"];
    [stairs setAmplitudes:@[@0, @-10, @-5, @0, @5, @10, @10, @5, @0, @-5, @-10]];
    return stairs;
}

#pragma mark - NSCoder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_amplitudes forKey:@"amplitudes"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (!(self = [super init])) {return nil;}
    id title = [coder decodeObjectForKey:@"title"];
    if (!title || ![title isKindOfClass:[NSString class]]) {
        title = @"";
    }
    _title = title;
    
    id amplitudes = [coder decodeObjectForKey:@"amplitudes"];
    if (!amplitudes || ![amplitudes isKindOfClass:[NSArray class]] || [amplitudes count] != 11) {
        amplitudes = [[PREQ flat] amplitudes];
    }
    for (id i in amplitudes) {
        if (![i isKindOfClass:[NSNumber class]] || [i floatValue] > 12 || [i floatValue] < -12) {
            amplitudes = [[PREQ flat] amplitudes];
        }
    }
    _amplitudes = amplitudes;
    return self;
}

@end
