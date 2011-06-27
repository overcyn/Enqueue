#import "PRKindFormatter.h"
#import "PRTagEditor.h"


@implementation PRKindFormatter

- (NSString *)stringForObjectValue:(id)object 
{
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"Unknown File";
    }
    
    switch ([object intValue]) {
        case PRFileTypeUnknown:
            return @"Unknown File";
            break;
        case PRFileTypeAPE:
            return @"APE File";
            break;
        case PRFileTypeASF:
            return @"ASF File";
            break;
        case PRFileTypeFLAC:
            return @"FLAC File";
            break;
        case PRFileTypeMP4:
            return @"MP4 File";
            break;
        case PRFileTypeMPC:
            return @"Musepack File";
            break;
        case PRFileTypeMPEG:
            return @"MPEG File";
            break;
        case PRFileTypeOggFLAC:
            return @"OggFlac File";
            break;
        case PRFileTypeOggVorbis:
            return @"Vorbis File";
            break;
        case PRFileTypeOggSpeex:
            return @"Speex File";
            break;
        case PRFileTypeAIFF:
            return @"AIFF File";
            break;
        case PRFileTypeWAV:
            return @"WAV File";
            break;
        case PRFileTypeTrueAudio:
            return @"TrueAudio File";
            break;
        case PRFileTypeWavPack:
            return @"WavPack File";
            break;
        default:
            return @"Unknown File";
            break;
    }
}

- (BOOL)getObjectValue:(id *)obj 
			 forString:(NSString *)string
	  errorDescription:(NSString **)error 
{
    return NO;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
								 withDefaultAttributes:(NSDictionary *)attributes
{
	return nil;
}

@end
