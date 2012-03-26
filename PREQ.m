#import "PREQ.h"


@implementation PREQ

// ========================================
// Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    _title = @"";
    _amplitudes = [[NSArray arrayWithObjects:
                    [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0],
                    [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0],
                    [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0],
                    [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0],
                    [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0], 
                    [NSNumber numberWithFloat:0], nil] retain];
    return self;
}

+ (PREQ *)EQ {
    return [[[PREQ alloc] init] autorelease];
}

+ (PREQ *)EQWithEQ:(PREQ *)EQ_ {
    PREQ *EQ = [PREQ EQ];
    [EQ setTitle:[EQ_ title]];
    [EQ setAmplitudes:[EQ_ amplitudes]];
    return EQ;
}

- (void)dealloc {
    [_title release];
    [_amplitudes release];
    [super dealloc];
}

// ========================================
// Accessors

@synthesize title = _title, 
amplitudes = _amplitudes;

- (void)setAmp:(float)amp forFreq:(PREQFreq)freq {
    NSMutableArray *a = [NSMutableArray arrayWithArray:_amplitudes];
    [a replaceObjectAtIndex:freq withObject:[NSNumber numberWithFloat:amp]];
    [_amplitudes release];
    _amplitudes = [[NSArray arrayWithArray:a] retain];
}

- (float)ampForFreq:(PREQFreq)freq {
    return [[_amplitudes objectAtIndex:freq] floatValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"PREQ:%@ %@",_title,[_amplitudes class]];
}

// ========================================
// DefaultEQs

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
    [stairs setAmplitudes:[NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0], 
                           [NSNumber numberWithFloat:-10], [NSNumber numberWithFloat:-10],
                           [NSNumber numberWithFloat:-5], [NSNumber numberWithFloat:-5],
                           [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:0],
                           [NSNumber numberWithFloat:5], [NSNumber numberWithFloat:5],
                           [NSNumber numberWithFloat:10], [NSNumber numberWithFloat:10], nil]];
    return stairs;
}

+ (PREQ *)triangle {
    PREQ *stairs = [PREQ EQ];
    [stairs setTitle:@"Triangle"];
    [stairs setAmplitudes:[NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0], 
                           [NSNumber numberWithFloat:-10], [NSNumber numberWithFloat:-5],
                           [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:5],
                           [NSNumber numberWithFloat:10], [NSNumber numberWithFloat:10],
                           [NSNumber numberWithFloat:5], [NSNumber numberWithFloat:0],
                           [NSNumber numberWithFloat:-5], [NSNumber numberWithFloat:-10], nil]];
    return stairs;
}

// ========================================
// NSCoder

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
    _title = [title retain];
    
    id amplitudes = [coder decodeObjectForKey:@"amplitudes"];
    if (!amplitudes || ![amplitudes isKindOfClass:[NSArray class]] || [amplitudes count] != 11) {
        amplitudes = [[PREQ flat] amplitudes];
    }
    for (id i in amplitudes) {
        if (![i isKindOfClass:[NSNumber class]] || [i floatValue] > 12 || [i floatValue] < -12) {
            amplitudes = [[PREQ flat] amplitudes];
        }
    }
    _amplitudes = [amplitudes retain];
    return self;
}

@end
