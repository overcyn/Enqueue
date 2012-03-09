#import <Foundation/Foundation.h>

typedef enum {
    PREQFreqPreamp = 0,
    PREQFreq32,
    PREQFreq64,
    PREQFreq128,
    PREQFreq256,
    PREQFreq512,
    PREQFreq1k,
    PREQFreq2k,
    PREQFreq4k,
    PREQFreq8k,
    PREQFreq16k,
} PREQFreq;

@interface PREQ : NSObject <NSCoding>
{
    NSString *_title;
    NSArray *_amplitudes;
}

// ========================================
// Initialization

+ (PREQ *)EQ;
+ (PREQ *)EQWithEQ:(PREQ *)EQ;

// ========================================
// Accessors

@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSArray *amplitudes;

- (void)setAmp:(float)amp forFreq:(PREQFreq)freq;
- (float)ampForFreq:(PREQFreq)freq;

// ========================================
// DefaultEQs

+ (NSArray *)defaultEQs;
+ (PREQ *)flat;
+ (PREQ *)stairs;
+ (PREQ *)triangle;

@end
