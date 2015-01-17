#import "PRTagger.h"
#import "PRConnection.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRAlbumArtController.h"
#import "PRFileInfo.h"
#import <stdio.h>
#import <iostream>
#import <QTKit/QTMovie.h>
#import "SFBAudioEngine/AudioMetadata.h"
#import "taglib/taglib.h"
#import "taglib/tbytevector.h"
#import "taglib/mpegfile.h"
#import "taglib/asffile.h"
#import "taglib/aifffile.h"
#import "taglib/mp4file.h"
#import "taglib/mp4tag.h"
#import "taglib/apetag.h"
#import "taglib/flacfile.h"
#import "taglib/flacpicture.h"
#import "taglib/xiphcomment.h"
#import "taglib/apefile.h"
#import "taglib/oggflacfile.h"
#import "taglib/vorbisfile.h"
#import "taglib/speexfile.h"
#import "taglib/trueaudiofile.h"
#import "taglib/aifffile.h"
#import "taglib/mpcfile.h"
#import "taglib/wavfile.h"
#import "taglib/wavpackfile.h"
#import "taglib/id3v2tag.h"
#import "taglib/id3v2frame.h"
#import "taglib/id3v2header.h"
#import "taglib/id3v1tag.h"
#import "taglib/apetag.h"
#import "taglib/attachedpictureframe.h"
#import "taglib/commentsframe.h"
#import "taglib/fileRef.h"
#import "taglib/textidentificationframe.h"
#import "taglib/tstring.h"
#import "taglib/mp4coverart.h"
#import "taglib/unsynchronizedlyricsframe.h"
#import "mp4v2/mp4v2.h"
#import "mp4v2/itmf_tags.h"
#import "mp4v2/itmf_generic.h"
#import "SSCrypto/SSCrypto.h"
using namespace std;
using namespace TagLib;


@interface PRTagger ()
/* Tags */
+ (File *)fileAtURL:(NSURL *)URL type:(PRFileType *)fileType;
+ (id)validateValue:(id)value forItemAttr:(PRItemAttr *)attr;
+ (void)dictionaryValidateValues:(NSMutableDictionary *)dict;
+ (void)dictionaryAddDefaultValues:(NSMutableDictionary *)dict;
+ (void)dictionary:(NSMutableDictionary *)dict addPropertiesForURL:(NSURL *)URL;

/* Tag Reading */
+ (NSMutableDictionary *)tagsForAPEFile:(APE::File *)file;
+ (NSMutableDictionary *)tagsForASFFile:(ASF::File *)file;
+ (NSMutableDictionary *)tagsForFLACFile:(FLAC::File *)file;
+ (NSMutableDictionary *)tagsForMP4File:(MP4::File *)file;
+ (NSMutableDictionary *)tagsForMPCFile:(MPC::File *)file;
+ (NSMutableDictionary *)tagsForMPEGFile:(MPEG::File *)file;
+ (NSMutableDictionary *)tagsForOggFLACFile:(Ogg::FLAC::File *)file;
+ (NSMutableDictionary *)tagsForOggVorbisFile:(Ogg::Vorbis::File *)file;
+ (NSMutableDictionary *)tagsForOggSpeexFile:(Ogg::Speex::File *)file;
+ (NSMutableDictionary *)tagsForAIFFFile:(RIFF::AIFF::File *)file;;
+ (NSMutableDictionary *)tagsForWAVFile:(RIFF::WAV::File *)file;
+ (NSMutableDictionary *)tagsForTrueAudioFile:(TrueAudio::File *)file;
+ (NSMutableDictionary *)tagsForWavPackFile:(WavPack::File *)file;

+ (NSMutableDictionary *)tagsForASFTag:(ASF::Tag *)tag;
+ (NSMutableDictionary *)tagsForMP4Tag:(MP4::Tag *)tag;
+ (NSMutableDictionary *)tagsForID3v2Tag:(ID3v2::Tag *)tag;
+ (NSMutableDictionary *)tagsForID3v1Tag:(ID3v1::Tag *)tag;
+ (NSMutableDictionary *)tagsForAPETag:(APE::Tag *)tag;
+ (NSMutableDictionary *)tagsForXiphComment:(Ogg::XiphComment *)tag;

/* Tag Writing */
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr APEFile:(APE::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ASFFile:(ASF::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr FLACFile:(FLAC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MP4File:(MP4::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MPCFile:(MPC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MPEGFile:(MPEG::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggFLACFile:(Ogg::FLAC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggVorbisFile:(Ogg::Vorbis::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggSpeexFile:(Ogg::Speex::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr AIFFFile:(RIFF::AIFF::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr WAVFile:(RIFF::WAV::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr TrueAudioFile:(TrueAudio::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr WavPackFile:(WavPack::File *)file;

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MP4Tag:(MP4::Tag *)MP4Tag;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ASFTag:(ASF::Tag *)ASFTag;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ID3v2Tag:(ID3v2::Tag *)id3v2tag;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ID3v1Tag:(ID3v1::Tag *)id3v1tag;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr APETag:(APE::Tag *)apeTag;
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr XiphComment:(Ogg::XiphComment *)xiphComment;

/* Tag Misc */
+ (int)firstValue:(const char *)string;
+ (int)secondValue:(const char *)string;

+ (const char *)ID3v2FrameIDForAttribute:(PRItemAttr *)attribute;
+ (const char *)ASFAttributeNameForAttribute:(PRItemAttr *)attribute;
+ (const char *)APEKeyForAttribute:(PRItemAttr *)attribute;
+ (const char *)MP4CodeForAttribute:(PRItemAttr *)attribute;
+ (const char *)XiphFieldNameForAttribute:(PRItemAttr *)attribute;

+ (NSString *)genreForID3Genre:(NSString *)genre;
+ (NSString *)ID3GenreForGenre:(NSString *)genre;
@end


@implementation PRTagger

#pragma mark - Tags

+ (PRFileInfo *)infoForURL:(NSURL *)URL {
    // Tags
    NSMutableDictionary *tags = [PRTagger tagsForURL:URL];
    if (!tags) {
        return nil;
    }
    PRFileInfo *info = [PRFileInfo fileInfo];
    // Artwork
    NSData *data = [tags objectForKey:PRItemAttrArtwork];
    if (data) {
        NSImage *art = [[NSImage alloc] initWithData:data];
        [tags removeObjectForKey:PRItemAttrArtwork];
        if (art && [art isValid]) {
            [tags setObject:[NSNumber numberWithBool:TRUE] forKey:PRItemAttrArtwork];
            [info setArt:art];
        }
    }
    // Title
    if ([[tags objectForKey:PRItemAttrTitle] isEqualToString:@""]) {
        NSString *filename = [URL lastPathComponent];
        [tags setObject:filename forKey:PRItemAttrTitle];
    }
    // Dates & URLs
    for (id i in [tags allKeys]) {
        if ([[tags objectForKey:i] isKindOfClass:[NSDate class]]) {
            NSString *str = [(NSDate *)[tags objectForKey:i] description];
            [tags setObject:str forKey:i];
        } else if ([[tags objectForKey:i] isKindOfClass:[NSURL class]]) {
            NSString *str = [(NSURL *)[tags objectForKey:i] absoluteString];
            [tags setObject:str forKey:i];
        }
    }
    [info setAttributes:tags];
    return info;
}

+ (NSMutableDictionary *)tagsForURL:(NSURL *)URL {
    AudioMetadata *metadata = AudioMetadata::CreateMetadataForURL((__bridge CFURLRef)URL);
    if (!metadata) {
        return nil;
    }
    BOOL err = metadata->ReadMetadata();
    if (err == FALSE) {
        return nil;
    }
    NSNumber *(^formatKind)(CFStringRef) = ^(CFStringRef a) {
        PRFileType kind;
        if (CFEqual(a, CFSTR("Monkey's Audio"))) {
            kind = PRFileTypeAPE;
        } else if (CFEqual(a, CFSTR("FLAC"))) {
            kind = PRFileTypeFLAC;
        } else if (CFEqual(a, CFSTR("AAC")) || CFEqual(a, CFSTR("Apple Lossless"))) {
            kind = PRFileTypeMP4;
        } else if (CFEqual(a, CFSTR("Musepack"))) {
            kind = PRFileTypeMPC;
        } else if (CFEqual(a, CFSTR("MP3"))) {
            kind = PRFileTypeMPEG;
        } else if (CFEqual(a, CFSTR("Ogg FLAC"))) {
            kind = PRFileTypeOggFLAC;
        } else if (CFEqual(a, CFSTR("Ogg Vorbis"))) {
            kind = PRFileTypeOggVorbis;
        } else if (CFEqual(a, CFSTR("Ogg Speex"))) {
            kind = PRFileTypeOggSpeex;
        } else if (CFEqual(a, CFSTR("AIFF"))) {
            kind = PRFileTypeAIFF;
        } else if (CFEqual(a, CFSTR("WAVE"))) {
            kind = PRFileTypeWAV;
        } else if (CFEqual(a, CFSTR("True Audio"))) {
            kind = PRFileTypeTrueAudio;
        } else if (CFEqual(a, CFSTR("WavPack"))) {
            kind = PRFileTypeWavPack;
        } else {
            kind = PRFileTypeUnknown;
        }
        return [NSNumber numberWithInt:kind];
    };
    NSString *(^formatStr)(CFStringRef) = ^(CFStringRef a){
        NSString *b = (__bridge NSString *)a;
        if ([b length] > 255) {
            return [b substringToIndex:255];
        }
        return b;
    };
    NSString *(^formatLongStr)(CFStringRef) = ^(CFStringRef a){
        NSString *b = (__bridge NSString *)a;
        if ([b length] > 10000) {
            return [b substringToIndex:10000];
        }
        return b;
    };
    NSNumber *(^formatInt)(CFNumberRef) = ^(CFNumberRef a){
        NSNumber *b = (__bridge NSNumber *)a;
        if ([b intValue] < 0 || [b intValue] > 9999) {
            return [NSNumber numberWithInt:0];
        }
        return b;
    };
    NSNumber *(^formatTime)(CFNumberRef) = ^(CFNumberRef a){
        NSNumber *b = (__bridge NSNumber *)a;
        return [NSNumber numberWithInt:[b intValue] * 1000];
    };
    NSNumber *(^formatLongInt)(CFNumberRef) = ^(CFNumberRef a){
        return (__bridge NSNumber *)a;
    };
    NSNumber *(^formatYear)(CFStringRef) = ^(CFStringRef a){
        NSNumber *number = @([(__bridge NSString *)a intValue]);
        return formatInt((__bridge CFNumberRef)number);
    };
    NSNumber *(^formatBool)(CFBooleanRef) = ^(CFBooleanRef a){
        if (!a) {
            return (NSNumber *)nil;
        }
        return [NSNumber numberWithBool:CFBooleanGetValue(a)];
    };
//    NSData *(^formatArt)(CFDataRef) = ^(CFDataRef a){
//        return (NSData *)a;
//    };
    
    if ([formatKind(metadata->GetFormatName()) intValue] == PRFileTypeUnknown) {
        return nil;
    }
    
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    /* File Attributes */
    [tags setValue:[URL absoluteString] forKey:PRItemAttrPath];
    [tags setValue:[PRTagger sizeForURL:URL] forKey:PRItemAttrSize];
    [tags setValue:[PRTagger checkSumForURL:URL] forKey:PRItemAttrCheckSum];
    [tags setValue:[PRTagger lastModifiedForURL:URL] forKey:PRItemAttrLastModified];
    /* Song Attributes */
    [tags setValue:formatKind(metadata->GetFormatName()) forKey:PRItemAttrKind];
    [tags setValue:formatLongInt(metadata->GetChannelsPerFrame()) forKey:PRItemAttrChannels];
   	[tags setValue:formatTime(metadata->GetDuration()) forKey:PRItemAttrTime];
   	[tags setValue:formatLongInt(metadata->GetBitrate()) forKey:PRItemAttrBitrate];
   	[tags setValue:formatLongInt(metadata->GetSampleRate()) forKey:PRItemAttrSampleRate];
    /* String Tags */
    [tags setValue:formatStr(metadata->GetTitle()) forKey:PRItemAttrTitle];
    [tags setValue:formatStr(metadata->GetArtist()) forKey:PRItemAttrArtist];
    [tags setValue:formatStr(metadata->GetAlbumArtist()) forKey:PRItemAttrAlbumArtist];
    [tags setValue:formatStr(metadata->GetAlbumTitle()) forKey:PRItemAttrAlbum];
   	[tags setValue:formatStr(metadata->GetComposer()) forKey:PRItemAttrComposer];
    [tags setValue:formatStr(metadata->GetGenre()) forKey:PRItemAttrGenre];
    [tags setValue:formatLongStr(metadata->GetComment()) forKey:PRItemAttrComments];
   	[tags setValue:formatLongStr(metadata->GetLyrics()) forKey:PRItemAttrLyrics];
    /* Number Tags */
   	[tags setValue:formatInt(metadata->GetTrackNumber()) forKey:PRItemAttrTrackNumber];
   	[tags setValue:formatInt(metadata->GetTrackTotal()) forKey:PRItemAttrTrackCount];
   	[tags setValue:formatInt(metadata->GetDiscNumber()) forKey:PRItemAttrDiscNumber];
   	[tags setValue:formatInt(metadata->GetDiscTotal()) forKey:PRItemAttrDiscCount];
    [tags setValue:formatBool(metadata->GetCompilation()) forKey:PRItemAttrCompilation];
    [tags setValue:formatYear(metadata->GetReleaseDate()) forKey:PRItemAttrYear];
    return tags;

    /*
    NSMutableDictionary *tags;
    PRFileType fileType;
    File *file = [PRTagger fileAtURL:URL type:&fileType];
    switch (fileType) {
        case PRFileTypeAPE:
            tags = [PRTagger tagsForAPEFile:reinterpret_cast<APE::File *>(file)];
            break;
        case PRFileTypeASF:
            tags = [PRTagger tagsForASFFile:reinterpret_cast<ASF::File *>(file)];
            break;
        case PRFileTypeFLAC:
            tags = [PRTagger tagsForFLACFile:reinterpret_cast<FLAC::File *>(file)];
            break;
        case PRFileTypeMP4:
            tags = [PRTagger tagsForMP4File:reinterpret_cast<MP4::File *>(file)];
            break;
        case PRFileTypeMPC:
            tags = [PRTagger tagsForMPCFile:reinterpret_cast<MPC::File *>(file)];
            break;
        case PRFileTypeMPEG:
            tags = [PRTagger tagsForMPEGFile:reinterpret_cast<MPEG::File *>(file)];
            break;
        case PRFileTypeOggFLAC:
            tags = [PRTagger tagsForOggFLACFile:reinterpret_cast<Ogg::FLAC::File *>(file)];
            break;
        case PRFileTypeOggSpeex:
            tags = [PRTagger tagsForOggSpeexFile:reinterpret_cast<Ogg::Speex::File *>(file)];
            break;
        case PRFileTypeOggVorbis:
            tags = [PRTagger tagsForOggVorbisFile:reinterpret_cast<Ogg::Vorbis::File *>(file)];
            break;
        case PRFileTypeAIFF:
            tags = [PRTagger tagsForAIFFFile:reinterpret_cast<RIFF::AIFF::File *>(file)];
            break;
        case PRFileTypeWAV:
            tags = [PRTagger tagsForWAVFile:reinterpret_cast<RIFF::WAV::File *>(file)];
            break;
        case PRFileTypeTrueAudio:
            tags = [PRTagger tagsForTrueAudioFile:reinterpret_cast<TrueAudio::File *>(file)];
            break;
        case PRFileTypeWavPack:
            tags = [PRTagger tagsForWavPackFile:reinterpret_cast<WavPack::File *>(file)];
            break;
        case PRFileTypeUnknown:
        default:
            return nil;
            break;
    }
    delete file;
    [PRTagger dictionaryValidateValues:tags];
    [PRTagger dictionaryAddDefaultValues:tags];
    [PRTagger dictionary:tags addPropertiesForURL:URL];
    [tags setObject:[NSNumber numberWithInt:fileType] forKey:PRItemAttrKind];
    return tags;
     */
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr URL:(NSURL *)URL {
    tag = [PRTagger validateValue:tag forItemAttr:attr];
    if (!tag) {
		@throw NSInvalidArgumentException;
	}
	
    PRFileType fileType;
    File *file = [PRTagger fileAtURL:URL type:&fileType];
    switch (fileType) {
        case PRFileTypeAPE:
            [PRTagger setTag:tag forAttribute:attr APEFile:reinterpret_cast<APE::File *>(file)];
            break;
        case PRFileTypeASF:
            [PRTagger setTag:tag forAttribute:attr ASFFile:reinterpret_cast<ASF::File *>(file)];
            break;
        case PRFileTypeFLAC:
            [PRTagger setTag:tag forAttribute:attr FLACFile:reinterpret_cast<FLAC::File *>(file)];
            break;
        case PRFileTypeMP4:
            [PRTagger setTag:tag forAttribute:attr MP4File:reinterpret_cast<MP4::File *>(file)];
            break;
        case PRFileTypeMPC:
            [PRTagger setTag:tag forAttribute:attr MPCFile:reinterpret_cast<MPC::File *>(file)];
            break;
        case PRFileTypeMPEG:
            [PRTagger setTag:tag forAttribute:attr MPEGFile:reinterpret_cast<MPEG::File *>(file)];
            break;
        case PRFileTypeOggFLAC:
            [PRTagger setTag:tag forAttribute:attr OggFLACFile:reinterpret_cast<Ogg::FLAC::File *>(file)];
            break;
        case PRFileTypeOggVorbis:
            [PRTagger setTag:tag forAttribute:attr OggVorbisFile:reinterpret_cast<Ogg::Vorbis::File *>(file)];
            break;
        case PRFileTypeOggSpeex:
            [PRTagger setTag:tag forAttribute:attr OggSpeexFile:reinterpret_cast<Ogg::Speex::File *>(file)];
            break;
        case PRFileTypeAIFF:
            [PRTagger setTag:tag forAttribute:attr AIFFFile:reinterpret_cast<RIFF::AIFF::File *>(file)];
            break;
        case PRFileTypeWAV:
            [PRTagger setTag:tag forAttribute:attr WAVFile:reinterpret_cast<RIFF::WAV::File *>(file)];
            break;
        case PRFileTypeTrueAudio:
            [PRTagger setTag:tag forAttribute:attr TrueAudioFile:reinterpret_cast<TrueAudio::File *>(file)];
            break;
        case PRFileTypeWavPack:
            [PRTagger setTag:tag forAttribute:attr WavPackFile:reinterpret_cast<WavPack::File *>(file)];
            break;
        case PRFileTypeUnknown:
        default:
            return;
            break;
    }
    file->save();
    delete file;
    return;
}

+ (BOOL)updateTagsForItem:(PRItemID *)item database:(PRConnection *)conn {
	PRFileInfo *info = [PRTagger infoForURL:[[conn library] URLForItem:item]];
	if (!info) {
		return FALSE;
	}
	
    BOOL change = FALSE;
    NSDictionary *attrs = [info attributes];
    for (PRItemAttr *i in [attrs allKeys]) {
        id value = [[conn library] valueForItem:item attr:i];
        if (![[attrs objectForKey:i] isEqual:value]) {
            change = TRUE;
        }
    }
    [[conn library] setAttrs:attrs forItem:item];
	[[conn albumArtController] clearTempArtwork];
	[[conn albumArtController] setTempArtwork:[[conn albumArtController] saveTempArtwork:[info art]] forItem:item];
	return change;
}

#pragma mark - Tags Priv

+ (File *)fileAtURL:(NSURL *)URL type:(PRFileType *)fileType {
    NSString *path = [URL path];
    NSString *pathExtension = [[path pathExtension] uppercaseString];
    File *file = nil;
    *fileType = PRFileTypeUnknown;
    
    if ([pathExtension compare:@"MP1"] == NSOrderedSame ||
        [pathExtension compare:@"MP2"] == NSOrderedSame ||
        [pathExtension compare:@"MP3"] == NSOrderedSame) {
        file = new MPEG::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeMPEG;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"AAC"] == NSOrderedSame ||
               [pathExtension compare:@"M4A"] == NSOrderedSame ||
               [pathExtension compare:@"MP4"] == NSOrderedSame ||
               [pathExtension compare:@"M4B"] == NSOrderedSame ||
               [pathExtension compare:@"M4R"] == NSOrderedSame) {
        UInt8 buf[PATH_MAX];
        if (!CFURLGetFileSystemRepresentation((CFURLRef)URL, FALSE, buf, PATH_MAX)) {
            return nil;
        }
        
        MP4FileHandle mp4FileHandle = MP4Read(reinterpret_cast<const char *>(buf));
        if (mp4FileHandle == MP4_INVALID_FILE_HANDLE) {
            MP4Close(mp4FileHandle);
            return nil;
        }
        
        if (MP4GetNumberOfTracks(mp4FileHandle) > 0) {
            // Should be type 'soun', media data name'mp4a'
            MP4TrackId trackID = MP4FindTrackId(mp4FileHandle, 0);
            // Verify this is an MPEG-4 audio file
            if(trackID == MP4_INVALID_TRACK_ID || strncmp("soun", MP4GetTrackType(mp4FileHandle, trackID), 4)) {
                MP4Close(mp4FileHandle);
                return nil;
            }
        }
        MP4Close(mp4FileHandle);
        
        file = new MP4::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeMP4;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"FLAC"] == NSOrderedSame) {
        file = new FLAC::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeFLAC;
            return file;
        }
        delete file;
        return nil;
//    } else if ([pathExtension compare:@"ASF"] == NSOrderedSame ||
//               [pathExtension compare:@"WMA"] == NSOrderedSame) {
//        file = new ASF::File([path UTF8String]);
//        if (file->isValid()) {
//            *fileType = PRFileTypeASF;
//            return file;
//        }
//        delete file;
//        return nil;
    } else if ([pathExtension compare:@"OGG"] == NSOrderedSame ||
               [pathExtension compare:@"OGA"] == NSOrderedSame ||
               [pathExtension compare:@"OGX"] == NSOrderedSame || 
               [pathExtension compare:@"SPX"] == NSOrderedSame) {
        file = new Ogg::Vorbis::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeOggVorbis;
            return file;
        }
        delete file;
        
        file = new Ogg::FLAC::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeOggFLAC;
            return file;
        }
        delete file;
        
        file = new Ogg::Speex::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeOggSpeex;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"AIFF"] == NSOrderedSame ||
               [pathExtension compare:@"AIF"] == NSOrderedSame) {
        file = new RIFF::AIFF::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeAIFF;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"WAV"] == NSOrderedSame) {
        file = new RIFF::WAV::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeWAV;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"MPC"] == NSOrderedSame ||
               [pathExtension compare:@"MPP"] == NSOrderedSame ||
               [pathExtension compare:@"MP+"] == NSOrderedSame) {
        file = new MPC::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeMPC;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"APE"] == NSOrderedSame) {
        file = new APE::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeAPE;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"TTA"] == NSOrderedSame) {
        file = new TrueAudio::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeTrueAudio;
            return file;
        }
        delete file;
        return nil;
    } else if ([pathExtension compare:@"WV"] == NSOrderedSame) {
        file = new WavPack::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeWavPack;
            return file;
        }
        delete file;
        return nil;
    } else {
        return nil;
    }
}

+ (void)dictionaryValidateValues:(NSMutableDictionary *)dict {
    for (PRItemAttr *i in [dict allKeys]) {
		id value = [dict objectForKey:i];
        id newValue = [PRTagger validateValue:value forItemAttr:i];
		if (value != newValue) {
			[dict setValue:newValue forKey:i];
		}
    }
}

+ (id)validateValue:(id)value forItemAttr:(PRItemAttr *)attr {
	if ([attr isEqualToString:PRItemAttrTitle] || 
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] || 
		[attr isEqualToString:PRItemAttrComposer] || 
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrGenre] ||
		[attr isEqualToString:PRItemAttrComments]) {
		if (![value isKindOfClass:[NSString class]]) {
			return nil;
		}
		if ([value length] > 255) {
			return [(NSString *)value substringToIndex:255];
		}
	} else if ([attr isEqualToString:PRItemAttrBPM] ||
			   [attr isEqualToString:PRItemAttrYear] ||
			   [attr isEqualToString:PRItemAttrTrackCount] ||
			   [attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrDiscCount] ||
			   [attr isEqualToString:PRItemAttrDiscNumber]) {
		if (![value isKindOfClass:[NSNumber class]] || 
			[value intValue] > 9999 || [value intValue] < 0) {
			return nil;
		}
	} else if ([attr isEqualToString:PRItemAttrCompilation]) {
		if (![value isKindOfClass:[NSNumber class]] || 
			[value intValue] > 1 || [value intValue] < 0) {
			return nil;
		}
	} else if ([attr isEqualToString:PRItemAttrLyrics]) {
		if (![value isKindOfClass:[NSString class]]) {
			return nil;
		}
		if ([value length] > 10000) {
			return [(NSString *)value substringToIndex:10000];
		}
	} else if ([attr isEqualToString:PRItemAttrArtwork]) {
		if (![value isKindOfClass:[NSData class]]) {
			return nil;
		}
	} else {
		@throw NSInvalidArgumentException;
	}
	return value;
}

+ (void)dictionaryAddDefaultValues:(NSMutableDictionary *)dict {
	static NSDictionary *defaultTags = nil;
	if (!defaultTags) {
		defaultTags = [[NSDictionary alloc] initWithObjectsAndKeys:
					   @"", PRItemAttrTitle,
					   @"", PRItemAttrArtist, 
					   @"", PRItemAttrAlbum,
					   @"", PRItemAttrComposer,
					   @"", PRItemAttrAlbumArtist,
					   @"", PRItemAttrGenre,
					   @"", PRItemAttrComments,
					   @"", PRItemAttrLyrics,
					   [NSNumber numberWithInt:0], PRItemAttrBPM,
					   [NSNumber numberWithInt:0], PRItemAttrYear,
					   [NSNumber numberWithInt:0], PRItemAttrTrackCount,
					   [NSNumber numberWithInt:0], PRItemAttrTrackNumber,
					   [NSNumber numberWithInt:0], PRItemAttrDiscCount,
					   [NSNumber numberWithInt:0], PRItemAttrDiscNumber, 
					   [NSNumber numberWithInt:0], PRItemAttrCompilation, nil];
	}
    for (PRItemAttr *i in [defaultTags allKeys]) {
        if (![dict valueForKey:i]) {
            [dict setValue:[defaultTags objectForKey:i] forKey:i];
        }
    }
}

+ (void)dictionary:(NSMutableDictionary *)dict addPropertiesForURL:(NSURL *)URL {
    NSString *path = [URL path];
	TagLib::FileRef fileRef([path UTF8String]);
	if(!fileRef.isNull() && fileRef.audioProperties()) {
		TagLib::AudioProperties *prop = fileRef.audioProperties();
        [dict setObject:[NSNumber numberWithInt:prop->length() * 1000] forKey:PRItemAttrTime];
        [dict setObject:[NSNumber numberWithInt:prop->bitrate()] forKey:PRItemAttrBitrate];
        [dict setObject:[NSNumber numberWithInt:prop->sampleRate()] forKey:PRItemAttrSampleRate];
        [dict setObject:[NSNumber numberWithInt:prop->channels()] forKey:PRItemAttrChannels];
	}
    NSData *checkSum = [PRTagger checkSumForFileAtPath:path];
    if (checkSum) {
        [dict setObject:checkSum forKey:PRItemAttrCheckSum];
    }
    NSNumber *size = [PRTagger sizeForFileAtPath:path];
    if (size) {
        [dict setObject:size forKey:PRItemAttrSize];
    }
    NSDate *lastModified = [PRTagger lastModifiedForFileAtPath:path];
    if (lastModified) {
        [dict setObject:[lastModified description] forKey:PRItemAttrLastPlayed];
    }
    [dict setObject:[URL absoluteString] forKey:PRItemAttrPath];
}

#pragma mark - Properties

+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    if (fileAttributes) {
        return [fileAttributes objectForKey:NSFileModificationDate];
    }
    return nil;
}

+ (NSData *)checkSumForFileAtPath:(NSString *)path {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fileHandle) {
        NSData *firstMegabyte = [fileHandle readDataOfLength:10000];
        return [SSCrypto getMD5ForData:firstMegabyte];
    }
    return nil;
}

+ (NSNumber *)sizeForFileAtPath:(NSString *)path {
    FSRef fileRef;
    OSStatus err = FSPathMakeRef ((const UInt8 *)[path fileSystemRepresentation], &fileRef, NULL);
    if (err == noErr) {
        FSCatalogInfo catalogInfo;
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr) {
            return [NSNumber numberWithUnsignedLongLong:catalogInfo.dataPhysicalSize];
        }
    }
    return nil;
}

+ (NSDate *)lastModifiedForURL:(NSURL *)URL {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[URL path] error:nil];
    if (fileAttributes) {
        return [fileAttributes objectForKey:NSFileModificationDate];
    }
    return nil;
}

+ (NSData *)checkSumForURL:(NSURL *)URL {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[URL path]];
    if (fileHandle) {
        NSData *firstMegabyte = [fileHandle readDataOfLength:10000];
        return [SSCrypto getMD5ForData:firstMegabyte];
    }
    return nil;
}

+ (NSNumber *)sizeForURL:(NSURL *)URL {
    FSRef fileRef;
    OSStatus err = FSPathMakeRef ((const UInt8 *)[[URL path] fileSystemRepresentation], &fileRef, NULL);
    if (err == noErr) {
        FSCatalogInfo catalogInfo;
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr) {
            return [NSNumber numberWithUnsignedLongLong:catalogInfo.dataPhysicalSize];
        }
    }
    return nil;
}

#pragma mark - Tag Reading Priv

+ (NSMutableDictionary *)tagsForAPEFile:(APE::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    APE::Tag *APETag = file->APETag(TRUE);
    if (APETag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForAPETag:APETag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForASFFile:(ASF::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ASF::Tag *ASFTag = file->tag();
    if (ASFTag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForASFTag:ASFTag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForFLACFile:(FLAC::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    ID3v2::Tag *ID3v2Tag = file->ID3v2Tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    Ogg::XiphComment *xiphComment = file->xiphComment(TRUE);
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    List<FLAC::Picture *> pictures = file->pictureList();
    if (pictures.size() > 0) {
        NSData *data = [NSData dataWithBytes:pictures.front()->data().data() length:pictures.front()->data().size()];
        [tags setObject:data forKey:PRItemAttrArtwork];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForMP4File:(MP4::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    MP4::Tag *MP4Tag = file->tag();
    if (MP4Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForMP4Tag:MP4Tag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForMPCFile:(MPC::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    APE::Tag *APETag = file->APETag(TRUE);
    if (APETag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForAPETag:APETag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForMPEGFile:(MPEG::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    ID3v2::Tag *ID3v2Tag = file->ID3v2Tag(TRUE);
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    APE::Tag *APETag = file->APETag();
    if (APETag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForAPETag:APETag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForOggFLACFile:(Ogg::FLAC::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForOggVorbisFile:(Ogg::Vorbis::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForOggSpeexFile:(Ogg::Speex::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;  
}

+ (NSMutableDictionary *)tagsForAIFFFile:(RIFF::AIFF::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v2::Tag *ID3v2Tag = file->tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForWAVFile:(RIFF::WAV::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v2::Tag *ID3v2Tag = file->tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForTrueAudioFile:(TrueAudio::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    ID3v2::Tag *ID3v2Tag = file->ID3v2Tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForWavPackFile:(WavPack::File *)file {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v1Tag:ID3v1Tag]];
    }
    APE::Tag *APETag = file->APETag(TRUE);
    if (APETag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForAPETag:APETag]];
    }
    return tags;
}

+ (NSMutableDictionary *)tagsForASFTag:(ASF::Tag *)tag {
    ASF::AttributeListMap tagMap = tag->attributeListMap();
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    
    // String
    void (^readAttr)(PRItemAttr *attr);
    readAttr = ^(PRItemAttr *attr) {
        const char *name = [PRTagger ASFAttributeNameForAttribute:attr];
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrTitle);
    readAttr(PRItemAttrArtist);
    readAttr(PRItemAttrAlbum);
    readAttr(PRItemAttrAlbumArtist);
    readAttr(PRItemAttrComposer);
    readAttr(PRItemAttrGenre);
    readAttr(PRItemAttrComposer);
    readAttr(PRItemAttrLyrics);
    
    // Number
    readAttr = ^(PRItemAttr *attr) {
        const char *name = [PRTagger ASFAttributeNameForAttribute:attr];
        if (!tagMap.contains(name)) {return;}
        NSNumber *number = [NSNumber numberWithInt:tagMap[name][0].toString().toInt()];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrBPM);
    readAttr(PRItemAttrYear);
    readAttr(PRItemAttrTrackNumber);
    readAttr(PRItemAttrTrackCount);
    
    // Number 1
    readAttr = ^(PRItemAttr *attr) {
        const char *name = [PRTagger ASFAttributeNameForAttribute:attr];
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:0] intValue]] forKey:attr];
    };
    readAttr(PRItemAttrDiscNumber);
    
    // Number 2
    readAttr = ^(PRItemAttr *attr) {
        const char *name = [PRTagger ASFAttributeNameForAttribute:attr];
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:1] intValue]] forKey:attr];
    };
    readAttr(PRItemAttrDiscCount);
    
    // Artwork
    readAttr = ^(PRItemAttr *attr) {
        const char *name = [PRTagger ASFAttributeNameForAttribute:attr];
        if (!tagMap.contains(name)) {return;}
        NSData *data = [NSData dataWithBytes:tagMap["WM/Picture"][0].toByteVector().data() 
                                      length:tagMap["WM/Picture"][0].toByteVector().size()];
        [tags setObject:data forKey:attr];
    };
    readAttr(PRItemAttrArtwork);
    return tags;
}

+ (NSMutableDictionary *)tagsForMP4Tag:(MP4::Tag *)tag {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    MP4::ItemListMap items = tag->itemListMap();
    
//    MP4::ItemListMap::ConstIterator it = tags.begin();
//    for (; it != tags.end(); it++) {
//        cout << (*it).first << " - \"" << (*it).second.toStringList() << " Int:" << (*it).second.toInt() << "\"" << endl;
//    }
    
    // Genre
    void (^readAttr)(PRItemAttr *attr);
    readAttr = ^(PRItemAttr *attr) {
        const char *code = "gnre";
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toInt()];
        NSString *string = [PRTagger genreForID3Genre:[number stringValue]];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrGenre);
    
    // String
    readAttr = ^(PRItemAttr *attr){
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSString *string = [NSString stringWithUTF8String:items[code].toStringList().toString(", ").toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrTitle);
    readAttr(PRItemAttrArtist);
    readAttr(PRItemAttrAlbum);
    readAttr(PRItemAttrAlbumArtist);
    readAttr(PRItemAttrComposer);
    readAttr(PRItemAttrGenre);
    readAttr(PRItemAttrComments);
    readAttr(PRItemAttrLyrics);
    
    // Number as String
    readAttr = ^(PRItemAttr *attr){
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toStringList().toString().toInt()];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrYear);
    
    // Number
    readAttr = ^(PRItemAttr *attr) {
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toInt()];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrBPM);
    readAttr(PRItemAttrCompilation);
    
    // Number 1
    readAttr = ^(PRItemAttr *attr) {
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toIntPair().first];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrDiscNumber);
    readAttr(PRItemAttrTrackNumber);
    
    // Number 1
    readAttr = ^(PRItemAttr *attr) {
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toIntPair().second];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrDiscCount);
    readAttr(PRItemAttrTrackCount);

    // Artwork
    readAttr = ^(PRItemAttr *attr) {
        const char *code = [PRTagger MP4CodeForAttribute:attr];
        if (!items.contains(code)) {return;}
        NSData *data = [NSData dataWithBytes:items[code].toCoverArtList().front().data().data() 
                                      length:items[code].toCoverArtList().front().data().size()];
        [tags setObject:data forKey:attr];
    };
    readAttr(PRItemAttrArtwork);
    return tags;
}

+ (NSMutableDictionary *)tagsForID3v2Tag:(TagLib::ID3v2::Tag *)tag {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    
//    ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
//    for(; it != tag->frameList().end(); it++) {
//        cout << (*it)->frameID() << " - \"" << (*it)->toString() << "\"" << endl;
//    }
    
    // String
    void (^readAttr)(PRItemAttr *attr);
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrTitle);
    readAttr(PRItemAttrArtist);
    readAttr(PRItemAttrAlbum);
    readAttr(PRItemAttrAlbumArtist);
    readAttr(PRItemAttrComposer);
    
    // Genre
    readAttr = ^(PRItemAttr *attr){
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:[self genreForID3Genre:string] forKey:attr];
    };
    readAttr(PRItemAttrGenre);
    
    // Comments
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        for (int i = 0; i < tag->frameListMap()[frameID].size(); i++) {
            ID3v2::CommentsFrame *frame = dynamic_cast<ID3v2::CommentsFrame *>(tag->frameListMap()[frameID][i]);
            if (!frame) {continue;}
            NSString *description = [NSString stringWithUTF8String:frame->description().toCString(TRUE)];
            if ([description isEqualToString:@"iTunes_CDDB_IDs"] || [description isEqualToString:@"iTunSMPB"] ||
                [description isEqualToString:@"iTunPGAP"] || [description isEqualToString:@"iTunNORM"]) {continue;}
            NSString *string = [NSString stringWithUTF8String:frame->toString().toCString(TRUE)];
            [tags setObject:string forKey:attr];
            return;
        }
    };
    readAttr(PRItemAttrComments);
    
    // Lyrics
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        ID3v2::UnsynchronizedLyricsFrame *frame = dynamic_cast<ID3v2::UnsynchronizedLyricsFrame *>(tag->frameListMap()[frameID].front());
        if (!frame) {return;}
        NSString *string = [NSString stringWithUTF8String:frame->toString().toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrLyrics);
    
    // Number
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID;
		if ([attr isEqualToString:@"TDAT"]) {
			frameID = "TDAT";
			attr = PRItemAttrYear;
		} else if ([attr isEqualToString:@"YEAR"]) {
			frameID = "YEAR";
			attr = PRItemAttrYear;
		} else {
			frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
		}
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:[NSNumber numberWithInt:[string intValue]] forKey:attr];
    };
    readAttr(@"TDAT");
    readAttr(@"YEAR");
    readAttr(PRItemAttrYear);
    readAttr(PRItemAttrBPM);
    readAttr(PRItemAttrCompilation);
    
    // Number 1
    readAttr = ^(PRItemAttr *attr){
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:0] intValue]] forKey:attr];
    };
    readAttr(PRItemAttrTrackNumber);
    readAttr(PRItemAttrDiscNumber);
    
    // Number 2
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:1] intValue]] forKey:attr];
    };
    readAttr(PRItemAttrTrackCount);
    readAttr(PRItemAttrDiscCount);
    
    // Artwork
    readAttr = ^(PRItemAttr *attr) {
        const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        ID3v2::AttachedPictureFrame *frame = dynamic_cast<ID3v2::AttachedPictureFrame *>(tag->frameListMap()["APIC"].front());
        if (!frame) {return;}
        NSData *data = [NSData dataWithBytes:frame->picture().data() length:frame->picture().size()];
        [tags setObject:data forKey:attr];
    };
    readAttr(PRItemAttrArtwork);
    return tags;
}

+ (NSMutableDictionary *)tagsForID3v1Tag:(TagLib::ID3v1::Tag *)tag {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    [tags setObject:[NSString stringWithUTF8String:tag->title().toCString(TRUE)] forKey:PRItemAttrTitle];
    [tags setObject:[NSString stringWithUTF8String:tag->artist().toCString(TRUE)] forKey:PRItemAttrArtist];
    [tags setObject:[NSString stringWithUTF8String:tag->album().toCString(TRUE)] forKey:PRItemAttrAlbum];
    [tags setObject:[NSString stringWithUTF8String:tag->comment().toCString(TRUE)] forKey:PRItemAttrComments];
    [tags setObject:[NSNumber numberWithInt:tag->year()] forKey:PRItemAttrYear];
    [tags setObject:[NSNumber numberWithInt:tag->track()] forKey:PRItemAttrTrackNumber];
    [tags setObject:[PRTagger genreForID3Genre:[NSString stringWithUTF8String:tag->genre().toCString(TRUE)]] forKey:PRItemAttrGenre];
//    NSLog(@"ID3v1:%@",tags);
    return tags;
}

+ (NSMutableDictionary *)tagsForAPETag:(TagLib::APE::Tag *)tag {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    APE::ItemListMap itemListMap = tag->itemListMap();
    
//    APE::ItemListMap::ConstIterator it = itemListMap.begin();
//    for(; it != itemListMap.end(); it++) {
//        cout << (*it).first << ". - \"" << (*it).second.toString() << "\"" << endl;
//    }
    
    // String
    void (^readAttr)(PRItemAttr *attr);
    readAttr = ^(PRItemAttr *attr){
        const char *key = [PRTagger APEKeyForAttribute:attr];
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrTitle);
    readAttr(PRItemAttrArtist);
    readAttr(PRItemAttrAlbum);
    readAttr(PRItemAttrAlbumArtist);
    readAttr(PRItemAttrComposer);
    readAttr(PRItemAttrComments);
    readAttr(PRItemAttrLyrics);
    readAttr(PRItemAttrGenre);

    // Number
    readAttr = ^(PRItemAttr *attr) {
        const char *key = [PRTagger APEKeyForAttribute:attr];
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSNumber *number = [NSNumber numberWithInt:[string intValue]];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrBPM);
    readAttr(PRItemAttrYear);
    readAttr(PRItemAttrCompilation);
    
    // Number 1
    readAttr = ^(PRItemAttr *attr) {
        const char *key = [PRTagger APEKeyForAttribute:attr];
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        NSNumber *number = [NSNumber numberWithInt:[[array objectAtIndex:0] intValue]];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrTrackNumber);
    readAttr(PRItemAttrDiscNumber);
    
    // Number 2
    readAttr = ^(PRItemAttr *attr) {
        const char *key = [PRTagger APEKeyForAttribute:attr];
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        NSNumber *number = [NSNumber numberWithInt:[[array objectAtIndex:1] intValue]];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrTrackCount);
    readAttr(PRItemAttrDiscCount);
    return tags;
}

+ (NSMutableDictionary *)tagsForXiphComment:(TagLib::Ogg::XiphComment *)tag; {
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    TagLib::Ogg::FieldListMap tagMap = tag->fieldListMap();
    
//    TagLib::Ogg::FieldListMap::ConstIterator it = tagMap.begin();
//    for(; it != tagMap.end(); it++) {
//        NSLog(@"key:%s field:%s",(*it).first.toCString(TRUE),(*it).second.toString().toCString(TRUE));
//    }
    
    // String
    void (^readAttr)(PRItemAttr *attr);
    readAttr = ^(PRItemAttr *attr){
        const char *field = [PRTagger XiphFieldNameForAttribute:attr];
        if (!tagMap.contains(field)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[field].front().toCString(TRUE)];
        [tags setObject:string forKey:attr];
    };
    readAttr(PRItemAttrTitle);
    readAttr(PRItemAttrArtist);
    readAttr(PRItemAttrAlbum);
    readAttr(PRItemAttrAlbumArtist);
    readAttr(PRItemAttrComposer);
    readAttr(PRItemAttrGenre);
    readAttr(PRItemAttrComments);
    readAttr(PRItemAttrLyrics);
    
    readAttr = ^(PRItemAttr *attr) {
        const char *field = [PRTagger XiphFieldNameForAttribute:attr];
        if (!tagMap.contains(field)) {return;}
        NSNumber *number = [NSNumber numberWithInt:tagMap[field].front().stripWhiteSpace().toInt()];
        [tags setObject:number forKey:attr];
    };
    readAttr(PRItemAttrYear);
    readAttr(PRItemAttrBPM);
    readAttr(PRItemAttrTrackNumber);
    readAttr(PRItemAttrTrackCount);
    readAttr(PRItemAttrDiscNumber);
    readAttr(PRItemAttrDiscCount);
    readAttr(PRItemAttrCompilation);
    return tags;    
}

#pragma mark - Tag Writing Priv

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr APEFile:(APE::File *)file {
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1Tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[PRTagger setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ASFFile:(ASF::File *)file {
    ASF::Tag *ASFTag = file->tag();
    if (ASFTag) {
        [PRTagger setTag:tag forAttribute:attr ASFTag:ASFTag];
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr FLACFile:(FLAC::File *)file {
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag();
	if (ID3v2tag) {
		[PRTagger setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
    TagLib::Ogg::XiphComment *xiphComment = file->xiphComment(TRUE);
	if (xiphComment) {
		[PRTagger setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
    if ([attr isEqualToString:PRItemAttrArtwork]) {
        file->removePictures();
        NSData *data = tag;
        if ([data length] != 0) {
            FLAC::Picture *p = new FLAC::Picture();
            p->setData(ByteVector((const char *)[data bytes], [data length]));
            file->addPicture(p);
        }
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MP4File:(MP4::File *)file {
    MP4::Tag *MP4Tag = file->tag();
    if (MP4Tag) {
        [PRTagger setTag:tag forAttribute:attr MP4Tag:MP4Tag];
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MPCFile:(MPC::File *)file {
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[PRTagger setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MPEGFile:(MPEG::File *)file {
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag(TRUE);
	if (ID3v2tag) {
		[PRTagger setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
	APE::Tag *APETag = file->APETag();
	if (APETag) {
		[PRTagger setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggFLACFile:(Ogg::FLAC::File *)file {
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[PRTagger setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggVorbisFile:(Ogg::Vorbis::File *)file {
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[PRTagger setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr OggSpeexFile:(Ogg::Speex::File *)file {
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[PRTagger setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr AIFFFile:(RIFF::AIFF::File *)file {
    TagLib::ID3v2::Tag *ID3v2tag = file->tag();
	if (ID3v2tag) {
		[PRTagger setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr WAVFile:(RIFF::WAV::File *)file {
    TagLib::ID3v2::Tag *ID3v2tag = file->tag();
	if (ID3v2tag) {
		[PRTagger setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr TrueAudioFile:(TrueAudio::File *)file {
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag(TRUE);
	if (ID3v2tag) {
		[PRTagger setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr WavPackFile:(WavPack::File *)file {
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [PRTagger setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[PRTagger setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ASFTag:(ASF::Tag *)ASFTag {
    ASF::AttributeListMap &attributeListMap = ASFTag->attributeListMap();
    const char *ASFAttributeName = [PRTagger ASFAttributeNameForAttribute:attr];
    ASF::Attribute ASFAttribute;
    bool isAttr = FALSE;
    if ([attr isEqualToString:PRItemAttrTitle] ||
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] ||
		[attr isEqualToString:PRItemAttrComposer] ||
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrComments] ||
		[attr isEqualToString:PRItemAttrGenre] ||
		[attr isEqualToString:PRItemAttrYear] ||
		[attr isEqualToString:PRItemAttrBPM] ||
		[attr isEqualToString:PRItemAttrLyrics]) {
		if ([tag count] == 0) {
            ASFAttribute = String([tag UTF8String], String::UTF8);
            isAttr = TRUE;
        }
    } else if ([attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrDiscNumber]) {
        int secondaryValue = 0;
        if (attributeListMap.contains(ASFAttributeName) && attributeListMap[ASFAttributeName].size() > 0) {
            secondaryValue = [PRTagger secondValue:attributeListMap[ASFAttributeName][0].toString().toCString(TRUE)];
        }
        if (secondaryValue == 0 && [tag intValue] != 0) {
            ASFAttribute = String([[tag stringValue] UTF8String], String::UTF8);
            isAttr = TRUE;
        } else if (secondaryValue != 0) {
            tag = [NSString stringWithFormat:@"%.1d/%d", [tag intValue], secondaryValue];
            ASFAttribute = String([tag UTF8String], String::UTF8);
            isAttr = TRUE;
        }
        ASFTag->removeItem("WM/Track");
    } else if ([attr isEqualToString:PRItemAttrTrackCount] ||
			   [attr isEqualToString:PRItemAttrDiscCount]) {
		int secondaryValue = 0;
		if (attributeListMap.contains(ASFAttributeName) && attributeListMap[ASFAttributeName].size() > 0) {
			secondaryValue = [PRTagger secondValue:attributeListMap[ASFAttributeName][0].toString().toCString(TRUE)];
		}
		if (secondaryValue != 0 && [tag intValue] == 0) {
			tag = [NSString stringWithFormat:@"%d", secondaryValue];
			ASFAttribute = String([tag UTF8String], String::UTF8);
			isAttr = TRUE;
		} else if ([tag intValue] != 0) {
			tag = [NSString stringWithFormat:@"%.1d/%@", secondaryValue, tag];
			ASFAttribute = String([tag UTF8String], String::UTF8);
			isAttr = TRUE;
		}
		ASFTag->removeItem("WM/Track");
	} else if ([attr isEqualToString:PRItemAttrArtwork]) {
		NSData *data = tag;
		if ([data length] != 0) {
			ASF::Picture p;
			p.setPicture(ByteVector((char *)[data bytes], [data length]));
			ASFAttribute = ASF::Attribute(p);
			isAttr = TRUE;
		}
	} else {
		return;
	}
    
    if (isAttr) {
        ASFTag->setAttribute(ASFAttributeName, ASFAttribute);
    } else {
        ASFTag->removeItem(ASFAttributeName);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr MP4Tag:(MP4::Tag *)MP4Tag {
    MP4::ItemListMap &itemListMap = MP4Tag->itemListMap();
    const char *MP4Code = [PRTagger MP4CodeForAttribute:attr];
    MP4::Item item;
    bool isItem = FALSE;
	
	if ([attr isEqualToString:PRItemAttrTitle] ||
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] ||
		[attr isEqualToString:PRItemAttrComposer] ||
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrComments] ||
		[attr isEqualToString:PRItemAttrLyrics]) {
		if ([tag length] != 0) {
			item = StringList(String([tag UTF8String], String::UTF8));
			isItem = TRUE;
		}
	} else if ([attr isEqualToString:PRItemAttrGenre]) {
		if ([tag length] != 0) {
			item = StringList(String([tag UTF8String], String::UTF8));
			isItem = TRUE;
		}
		itemListMap.erase("gnre");
	} else if ([attr isEqualToString:PRItemAttrYear]) {
		tag = [tag stringValue];
		if ([tag length] != 0) {
			item = StringList(String([tag UTF8String], String::UTF8));
			isItem = TRUE;
		}
	} else if ([attr isEqualToString:PRItemAttrCompilation] ||
			   [attr isEqualToString:PRItemAttrBPM]) {
		if ([tag intValue] != 0) {
			item = [tag intValue];
			isItem = TRUE;
		}
	} else if ([attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrDiscNumber]) {
		int secondaryNumber = 0;
		if (itemListMap.contains(MP4Code)) {
			secondaryNumber = itemListMap[MP4Code].toIntPair().second;
		}
		if (secondaryNumber != 0 || [tag intValue] != 0) {
			item = MP4::Item([tag intValue], secondaryNumber);
			isItem = TRUE;
		}
	} else if ([attr isEqualToString:PRItemAttrTrackCount] ||
			   [attr isEqualToString:PRItemAttrDiscCount]) {
		int secondaryNumber = 0;
		if (itemListMap.contains(MP4Code)) {
			secondaryNumber = itemListMap[MP4Code].toIntPair().first;
		}
		if (secondaryNumber != 0 || [tag intValue] != 0) {
			item = MP4::Item(secondaryNumber, [tag intValue]);
			isItem = TRUE;
		}
	} else if ([attr isEqualToString:PRItemAttrArtwork]) {
		NSData *data = tag;
		if ([data length] != 0) {
			MP4::CoverArtList list;
			list.append(MP4::CoverArt(MP4::CoverArt::PNG, ByteVector((char *)[data bytes], [data length])));
			item = MP4::Item(list);
			isItem = TRUE;
		}
	} else {
		return;
	}
	
    if (isItem) {
        itemListMap.insert(MP4Code, item);
    } else {
        itemListMap.erase(MP4Code);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ID3v2Tag:(ID3v2::Tag *)id3v2tag {
	TagLib::ID3v2::FrameListMap frameListMap = id3v2tag->frameListMap();
	const char *frameID = [PRTagger ID3v2FrameIDForAttribute:attr];
    ID3v2::Frame *frame = NULL;
	
	if ([attr isEqualToString:PRItemAttrTitle] ||
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] ||
		[attr isEqualToString:PRItemAttrComposer] ||
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrGenre]) {
		if ([tag length] != 0) {
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f;
		}
	} else if ([attr isEqualToString:PRItemAttrComments]) {
		id3v2tag->removeFrames(frameID);
		if ([tag length] != 0) {
			ID3v2::CommentsFrame *f = new ID3v2::CommentsFrame(String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			f->setLanguage(ByteVector("eng", 3));
			frame = f;
		}
	} else if ([attr isEqualToString:PRItemAttrLyrics]) {
		id3v2tag->removeFrames(frameID);
		if ([tag length] != 0) {
			ID3v2::UnsynchronizedLyricsFrame *f = new ID3v2::UnsynchronizedLyricsFrame(String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			f->setLanguage(ByteVector("eng", 3));
			frame = f;
		}
	} else if ([attr isEqualToString:PRItemAttrCompilation] ||
			   [attr isEqualToString:PRItemAttrYear] ||
			   [attr isEqualToString:PRItemAttrBPM]) {
		if ([tag intValue] != 0) {
			tag = [tag stringValue];
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f;
		}
	} else if ([attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrDiscNumber]) {
		int secondaryValue = 0;
		if ([attr isEqualToString:PRItemAttrTrackNumber]) {
			secondaryValue = [[[PRTagger tagsForID3v2Tag:id3v2tag] objectForKey:PRItemAttrTrackCount] intValue];
		} else {
			secondaryValue = [[[PRTagger tagsForID3v2Tag:id3v2tag] objectForKey:PRItemAttrDiscCount] intValue];
		}
		if (secondaryValue == 0 && [tag intValue] != 0) {
			tag = [tag stringValue];
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f;
		} else if (secondaryValue != 0) {
			tag = [NSString stringWithFormat:@"%.1d/%d", [tag intValue], secondaryValue];
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f;
		}
	} else if ([attr isEqualToString:PRItemAttrTrackCount] ||
			   [attr isEqualToString:PRItemAttrDiscCount]) {
		int secondaryValue = 0;
		if ([attr isEqualToString:PRItemAttrTrackCount]) {
			secondaryValue = [[[PRTagger tagsForID3v2Tag:id3v2tag] objectForKey:PRItemAttrDiscNumber] intValue];
		} else {
			secondaryValue = [[[PRTagger tagsForID3v2Tag:id3v2tag] objectForKey:PRItemAttrDiscCount] intValue];
		}
		if (secondaryValue != 0 && [tag intValue] == 0) {
			tag = [NSString stringWithFormat:@"%d",secondaryValue];
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f;
		} else if ([tag intValue] != 0) {
			tag = [NSString stringWithFormat:@"%.1d/%d", secondaryValue, [tag intValue]];
			ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
			f->setText(TagLib::String([tag UTF8String], String::UTF8));
			frame = f; 
		}
	} else if ([attr isEqualToString:PRItemAttrArtwork]) {
		NSData *data = tag;
		if ([data length] != 0) {
			ID3v2::AttachedPictureFrame *f = new ID3v2::AttachedPictureFrame();
			f->setPicture(ByteVector((const char *)[data bytes], [data length]));
			frame = f;
		}
	} else {
		return;
	}
    
    id3v2tag->removeFrames(frameID);
    if (frame) {
		id3v2tag->addFrame(frame);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr ID3v1Tag:(ID3v1::Tag *)id3v1tag {
    int intValue = 0;
    String stringValue;
    if ([tag isKindOfClass:[NSNumber class]]) {
        intValue = [tag intValue];
    } else if ([tag isKindOfClass:[NSString class]]) {
        if ([attr isEqualToString:PRItemAttrGenre]) {
            tag = [PRTagger ID3GenreForGenre:tag];
        }
        stringValue = String([tag UTF8String], String::UTF8);
    }
    
	if ([attr isEqualToString:PRItemAttrTitle]) {
		id3v1tag->setTitle(stringValue);
	} else if ([attr isEqualToString:PRItemAttrAlbum]) {
		id3v1tag->setAlbum(stringValue);
	} else if ([attr isEqualToString:PRItemAttrArtist]) {
		id3v1tag->setArtist(stringValue);
	} else if ([attr isEqualToString:PRItemAttrComments]) {
		id3v1tag->setComment(stringValue);
	} else if ([attr isEqualToString:PRItemAttrGenre]) {
		id3v1tag->setGenre(stringValue);
	} else if ([attr isEqualToString:PRItemAttrYear]) {
		id3v1tag->setYear(intValue);
	} else if ([attr isEqualToString:PRItemAttrTrackNumber]) {
		id3v1tag->setTrack(intValue);
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr APETag:(APE::Tag *)apeTag {
    const APE::ItemListMap &itemListMap = apeTag->itemListMap();
    const char *APEKey = [PRTagger APEKeyForAttribute:attr];
    APE::Item item;
	if ([attr isEqualToString:PRItemAttrTitle] ||
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] ||
		[attr isEqualToString:PRItemAttrComposer] ||
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrComments] ||
		[attr isEqualToString:PRItemAttrGenre] ||
		[attr isEqualToString:PRItemAttrLyrics]) {
		if ([tag length] > 0) {
			item = APE::Item(APEKey, String([tag UTF8String], String::UTF8));
			apeTag->setItem(APEKey, item);
		} else {
			apeTag->removeItem(APEKey);
		}
	} else if ([attr isEqualToString:PRItemAttrBPM] ||
			   [attr isEqualToString:PRItemAttrYear] ||
			   [attr isEqualToString:PRItemAttrCompilation]) {
		if ([tag intValue] != 0) {
			item = APE::Item(APEKey, String([[tag stringValue] UTF8String], String::UTF8));
			apeTag->setItem(APEKey, item);
		} else {
			apeTag->removeItem(APEKey);
		}
	} else if ([attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrDiscNumber]) {
		int secondaryValue = 0;
		if (itemListMap[APEKey].toStringList().size() > 2) {
			secondaryValue = itemListMap[APEKey].toStringList()[1].toInt();
		}
		if (secondaryValue == 0 && [tag intValue] != 0) {
			item = APE::Item(APEKey, String([[tag stringValue] UTF8String], String::UTF8));
			apeTag->setItem(APEKey, item);
		} else if (secondaryValue != 0) {
			StringList list = StringList(String([[tag stringValue] UTF8String], String::UTF8));
			list.append(String::number(secondaryValue));
			item = APE::Item(APEKey, list);
			apeTag->setItem(APEKey, item);
		} else {
			apeTag->removeItem(APEKey);
		}
	} else if ([attr isEqualToString:PRItemAttrTrackCount] || 
			   [attr isEqualToString:PRItemAttrDiscCount]) {
		int secondaryValue = 0;
		if (itemListMap[APEKey].toStringList().size() > 1) {
			secondaryValue = itemListMap[APEKey].toStringList()[0].toInt();
		}
		if (secondaryValue != 0 && [tag intValue] == 0) {
			item = APE::Item(APEKey, String::number(secondaryValue));
			apeTag->setItem(APEKey, item);
		} else if ([tag intValue] != 0) {
			StringList list = StringList(String::number(secondaryValue));
			list.append(String([[tag stringValue] UTF8String], String::UTF8));
			item = APE::Item(APEKey, list);
			apeTag->setItem(APEKey, item);
		} else {
			apeTag->removeItem(APEKey);
		}
	}
}

+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr XiphComment:(Ogg::XiphComment *)xiphComment {
    const char *fieldName = [PRTagger XiphFieldNameForAttribute:attr];
	if ([attr isEqualToString:PRItemAttrTitle] ||
		[attr isEqualToString:PRItemAttrArtist] ||
		[attr isEqualToString:PRItemAttrAlbum] ||
		[attr isEqualToString:PRItemAttrComposer] ||
		[attr isEqualToString:PRItemAttrAlbumArtist] ||
		[attr isEqualToString:PRItemAttrComments] ||
		[attr isEqualToString:PRItemAttrGenre] ||
		[attr isEqualToString:PRItemAttrLyrics]) {
		if ([tag length] != 0) {
			xiphComment->addField(fieldName, TagLib::String([tag UTF8String], TagLib::String::UTF8), TRUE);
		} else {
			xiphComment->removeField(fieldName);
		}
	} else if ([attr isEqualToString:PRItemAttrBPM] ||
			   [attr isEqualToString:PRItemAttrYear] ||
			   [attr isEqualToString:PRItemAttrTrackNumber] ||
			   [attr isEqualToString:PRItemAttrTrackCount] ||
			   [attr isEqualToString:PRItemAttrDiscNumber] ||
			   [attr isEqualToString:PRItemAttrDiscCount] ||
			   [attr isEqualToString:PRItemAttrCompilation]) {
		if ([tag intValue] != 0) {
			xiphComment->addField(fieldName, TagLib::String([[tag stringValue] UTF8String], TagLib::String::UTF8), TRUE);
		} else {
			xiphComment->removeField(fieldName);
		}
	}
}

#pragma mark - Tags Misc

+ (int)firstValue:(const char *)string {
    NSArray *array = [[NSString stringWithUTF8String:string] componentsSeparatedByString:@"/"];
    int value = 0;
    if ([array count] >= 1) {
        value = [[array objectAtIndex:0] intValue];
        if (value > 9999 || value < 0) {
            value = 0;
        }
    }
    return value;
}

+ (int)secondValue:(const char *)string {
    NSArray *array = [[NSString stringWithUTF8String:string] componentsSeparatedByString:@"/"];
    int value = 0;
    if ([array count] == 2) {
        value = [[array objectAtIndex:1] intValue];
        if (value > 9999 || value < 0) {
            value = 0;
        }
    }
    return value;
}

+ (const char *)ID3v2FrameIDForAttribute:(PRItemAttr *)attribute {
    if ([attribute isEqual:PRItemAttrTitle]) {
        return "TIT2";
    } else if ([attribute isEqual:PRItemAttrArtist]) {
        return "TPE1";
    } else if ([attribute isEqual:PRItemAttrAlbum]) {
        return "TALB";
    } else if ([attribute isEqual:PRItemAttrComposer]) {
        return "TCOM";
    } else if ([attribute isEqual:PRItemAttrAlbumArtist]) {
        return "TPE2";
    } else if ([attribute isEqual:PRItemAttrBPM]) {
        return "TBPM";
    } else if ([attribute isEqual:PRItemAttrYear]) {
        return "TDRC";
    } else if ([attribute isEqual:PRItemAttrTrackNumber] || 
               [attribute isEqual:PRItemAttrTrackCount]) {
        return "TRCK";
    } else if ([attribute isEqual:PRItemAttrDiscNumber] ||
               [attribute isEqual:PRItemAttrDiscCount]) {
        return "TPOS";
    } else if ([attribute isEqual:PRItemAttrComments]) {
        return "COMM";
    } else if ([attribute isEqual:PRItemAttrGenre]) {
        return "TCON";
    } else if ([attribute isEqual:PRItemAttrArtwork]) {
        return "APIC";
    } else if ([attribute isEqual:PRItemAttrCompilation]) {
        return "TCMP";
    } else if ([attribute isEqual:PRItemAttrLyrics]) {
        return "USLT";
    } else {
        @throw NSInvalidArgumentException;
    }
}

+ (const char *)ASFAttributeNameForAttribute:(PRItemAttr *)attribute {
    if ([attribute isEqual:PRItemAttrTitle]) {
        return "Title";
    } else if ([attribute isEqual:PRItemAttrArtist]) {
        return "Author";
    } else if ([attribute isEqual:PRItemAttrAlbum]) {
        return "WM/AlbumTitle";
    } else if ([attribute isEqual:PRItemAttrComposer]) {
        return "WM/Composer";
    } else if ([attribute isEqual:PRItemAttrAlbumArtist]) {
        return "WM/AlbumArtist";
    } else if ([attribute isEqual:PRItemAttrBPM]) {
        return "WM/BeatsPerMinute";
    } else if ([attribute isEqual:PRItemAttrYear]) {
        return "WM/Year";
    } else if ([attribute isEqual:PRItemAttrTrackNumber] ||
			   [attribute isEqual:PRItemAttrTrackCount]) {
        return "WM/TrackNumber"; 
    } else if ([attribute isEqual:PRItemAttrDiscNumber] ||
			   [attribute isEqual:PRItemAttrDiscCount]) {
		return "WM/PartOfSet";
	} else if ([attribute isEqual:PRItemAttrComments]) {
		return "WM/Comments";
    } else if ([attribute isEqual:PRItemAttrGenre]) {
        return "WM/Genre";
    } else if ([attribute isEqual:PRItemAttrArtwork]) {
        return "WM/Picture";
    } else if ([attribute isEqual:PRItemAttrCompilation]) {
        return "WM/Comments";
    } else if ([attribute isEqual:PRItemAttrLyrics]) {
        return "WM/Lyrics";
    } else {
		@throw NSInvalidArgumentException;
    }
}

+ (const char *)APEKeyForAttribute:(PRItemAttr *)attribute {
    if ([attribute isEqual:PRItemAttrTitle]) {
        return "TITLE";
    } else if ([attribute isEqual:PRItemAttrArtist]) {
        return "ARTIST";
    } else if ([attribute isEqual:PRItemAttrAlbum]) {
        return "ALBUM";
    } else if ([attribute isEqual:PRItemAttrComposer]) {
        return "COMPOSER";
    } else if ([attribute isEqual:PRItemAttrAlbumArtist]) {
        return "ALBUMARTIST";
    } else if ([attribute isEqual:PRItemAttrBPM]) {
        return "BPM";
    } else if ([attribute isEqual:PRItemAttrYear]) {
        return "YEAR";
    } else if ([attribute isEqual:PRItemAttrTrackNumber] ||
               [attribute isEqual:PRItemAttrTrackCount]) {
        return "TRACK";
    } else if ([attribute isEqual:PRItemAttrDiscNumber] || 
               [attribute isEqual:PRItemAttrDiscCount]) {
        return "MEDIA";
    } else if ([attribute isEqual:PRItemAttrComments]) {
        return "COMMENT";
    } else if ([attribute isEqual:PRItemAttrGenre]) {
        return "GENRE";
    } else if ([attribute isEqual:PRItemAttrArtwork]) {
        @throw NSInvalidArgumentException;
    } else if ([attribute isEqual:PRItemAttrCompilation]) {
        return "COMPILATION";
    } else if ([attribute isEqual:PRItemAttrLyrics]) {
        return "LYRICS";
    } else {
        @throw NSInvalidArgumentException;
    }
}

+ (const char *)MP4CodeForAttribute:(PRItemAttr *)attribute {
    if ([attribute isEqual:PRItemAttrTitle]) {
        return "\251nam";
    } else if ([attribute isEqual:PRItemAttrArtist]) {
        return "\251ART";
    } else if ([attribute isEqual:PRItemAttrAlbum]) {
        return "\251alb";
    } else if ([attribute isEqual:PRItemAttrComposer]) {
        return "\251wrt";
    } else if ([attribute isEqual:PRItemAttrAlbumArtist]) {
        return "aART";	
    } else if ([attribute isEqual:PRItemAttrBPM]) {
        return "tmpo";
    } else if ([attribute isEqual:PRItemAttrYear]) {
        return "\251day";
    } else if ([attribute isEqual:PRItemAttrTrackNumber] || 
               [attribute isEqual:PRItemAttrTrackCount]) {
        return "trkn";
    } else if ([attribute isEqual:PRItemAttrDiscNumber] || 
               [attribute isEqual:PRItemAttrDiscCount]) {
        return "disk";
    } else if ([attribute isEqual:PRItemAttrComments]) {
        return "\251cmt";
    } else if ([attribute isEqual:PRItemAttrGenre]) {
        return "\251gen";
    } else if ([attribute isEqual:PRItemAttrArtwork]) {
        return "covr";
    } else if ([attribute isEqual:PRItemAttrCompilation]) {
        return "cpil";
    } else if ([attribute isEqual:PRItemAttrLyrics]) {
        return "\251lyr";
    } else {
        @throw NSInvalidArgumentException;
    }
}

+ (const char *)XiphFieldNameForAttribute:(PRItemAttr *)attribute {
    if ([attribute isEqual:PRItemAttrTitle]) {
        return "TITLE";
    } else if ([attribute isEqual:PRItemAttrArtist]) {
        return "ARTIST";
    } else if ([attribute isEqual:PRItemAttrAlbum]) {
        return "ALBUM";
    } else if ([attribute isEqual:PRItemAttrComposer]) {
        return "COMPOSER";
    } else if ([attribute isEqual:PRItemAttrAlbumArtist]) {
        return "ALBUMARTIST";
    } else if ([attribute isEqual:PRItemAttrBPM]) {
        return "BPM";
    } else if ([attribute isEqual:PRItemAttrYear]) {
        return "DATE";
    } else if ([attribute isEqual:PRItemAttrTrackNumber]) {
        return "TRACKNUMBER";
    } else if ([attribute isEqual:PRItemAttrTrackCount]) {
        return "TOTALTRACKS";
    } else if ([attribute isEqual:PRItemAttrDiscNumber]) {
        return "DISCNUMBER";
    } else if ([attribute isEqual:PRItemAttrDiscCount]) {
        return "TOTALDISCS";
    } else if ([attribute isEqual:PRItemAttrComments]) {
        return "DESCRIPTION";
    } else if ([attribute isEqual:PRItemAttrGenre]) {
        return "GENRE";
    } else if ([attribute isEqual:PRItemAttrArtwork]) {
        @throw NSInvalidArgumentException;
    } else if ([attribute isEqual:PRItemAttrCompilation]) {
        return "COMPILATION";
    } else if ([attribute isEqual:PRItemAttrLyrics]) {
        return "LYRICS";
    } else {
        @throw NSInvalidArgumentException;
    }
}

+ (NSString *)genreForID3Genre:(NSString *)genre {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PRID3Genres" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *string_ = [dictionary objectForKey:genre];
    
    if (string_) {
        return string_;
    }
    return genre;
}

+ (NSString *)ID3GenreForGenre:(NSString *)genre {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PRID3Genres" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *array = [dictionary allKeysForObject:genre];
    
    if ([array count] > 0) {
        return [array objectAtIndex:0];
    }
    return genre;
}

@end
