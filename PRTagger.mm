#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRAlbumArtController.h"
#import <stdio.h>
#import <iostream>
#import <QTKit/QTMovie.h>
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
#import "PRFileInfo.h"

#import "PRTagger.h"
#import "PRFileInfo.h"

using namespace std;
using namespace TagLib;

@interface PRTagger ()

// ========================================
// Tags

+ (File *)fileAtURL:(NSURL *)URL type:(PRFileType *)fileType;

// ========================================
// Tag Reading

+ (NSDictionary *)tagsForAPEFile:(APE::File *)file;
+ (NSDictionary *)tagsForASFFile:(ASF::File *)file;
+ (NSDictionary *)tagsForFLACFile:(FLAC::File *)file;
+ (NSDictionary *)tagsForMP4File:(MP4::File *)file;
+ (NSDictionary *)tagsForMPCFile:(MPC::File *)file;
+ (NSDictionary *)tagsForMPEGFile:(MPEG::File *)file;
+ (NSDictionary *)tagsForOggFLACFile:(Ogg::FLAC::File *)file;
+ (NSDictionary *)tagsForOggVorbisFile:(Ogg::Vorbis::File *)file;
+ (NSDictionary *)tagsForOggSpeexFile:(Ogg::Speex::File *)file;
+ (NSDictionary *)tagsForAIFFFile:(RIFF::AIFF::File *)file;
+ (NSDictionary *)tagsForWAVFile:(RIFF::WAV::File *)file;
+ (NSDictionary *)tagsForTrueAudioFile:(TrueAudio::File *)file;
+ (NSDictionary *)tagsForWavPackFile:(WavPack::File *)file;

+ (NSDictionary *)tagsForASFTag:(ASF::Tag *)tag;
+ (NSDictionary *)tagsForMP4Tag:(MP4::Tag *)tag;
+ (NSDictionary *)tagsForID3v2Tag:(ID3v2::Tag *)tag;
+ (NSDictionary *)tagsForID3v1Tag:(ID3v1::Tag *)tag;
+ (NSDictionary *)tagsForAPETag:(APE::Tag *)tag;
+ (NSDictionary *)tagsForXiphComment:(Ogg::XiphComment *)tag;

// ========================================
// Tag Writing

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr APEFile:(APE::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ASFFile:(ASF::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr FLACFile:(FLAC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MP4File:(MP4::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MPCFile:(MPC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MPEGFile:(MPEG::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggFLACFile:(Ogg::FLAC::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggVorbisFile:(Ogg::Vorbis::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggSpeexFile:(Ogg::Speex::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr AIFFFile:(RIFF::AIFF::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr WAVFile:(RIFF::WAV::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr TrueAudioFile:(TrueAudio::File *)file;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr WavPackFile:(WavPack::File *)file;

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MP4Tag:(MP4::Tag *)MP4Tag;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ASFTag:(ASF::Tag *)ASFTag;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ID3v2Tag:(ID3v2::Tag *)id3v2tag;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ID3v1Tag:(ID3v1::Tag *)id3v1tag;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr APETag:(APE::Tag *)apeTag;
+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr XiphComment:(Ogg::XiphComment *)xiphComment;

// ========================================
// Tag Miscellaneous

+ (int)firstValue:(const char *)string;
+ (int)secondValue:(const char *)string;

+ (const char *)ID3v2FrameIDForAttribute:(PRFileAttribute)attribute;
+ (const char *)ASFAttributeNameForAttribute:(PRFileAttribute)attribute;
+ (const char *)APEKeyForAttribute:(PRFileAttribute)attribute;
+ (const char *)MP4CodeForAttribute:(PRFileAttribute)attribute;
+ (const char *)XiphFieldNameForAttribute:(PRFileAttribute)attribute;

+ (NSString *)genreForID3Genre:(NSString *)genre;
+ (NSString *)ID3GenreForGenre:(NSString *)genre;

@end

@implementation PRTagger

// ========================================
// Tags
// ========================================

+ (PRFileInfo *)infoForURL:(NSURL *)URL
{
    PRFileInfo *info = [PRFileInfo fileInfo];
    NSDictionary *tags2 = [PRTagger tagsForURL:URL];
    if (!tags2) {
        return nil;
    }
    NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithDictionary:tags2];
    // Artwork
    NSData *data = [tags objectForKey:[NSNumber numberWithInt:PRAlbumArtFileAttribute]];
    NSImage *art = nil;
    if (data) {
        art = [[[NSImage alloc] initWithData:data] autorelease];
        [tags removeObjectForKey:[NSNumber numberWithInt:PRAlbumArtFileAttribute]];
        if (art && [art isValid]) {
            [tags setObject:[NSNumber numberWithBool:TRUE] forKey:[NSNumber numberWithInt:PRAlbumArtFileAttribute]];
            [info setArt:art];
        }
    }
    // Title
    if (![tags objectForKey:[NSNumber numberWithInt:PRTitleFileAttribute]] || 
        [[tags objectForKey:[NSNumber numberWithInt:PRTitleFileAttribute]] isEqualToString:@""]) {
        NSString *filename = [URL lastPathComponent];
        [tags setObject:filename forKey:[NSNumber numberWithInt:PRTitleFileAttribute]];
    }
    // Dates & URLs
    for (NSNumber *i in [tags allKeys]) {
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

+ (NSDictionary *)tagsForURL:(NSURL *)URL
{
    NSDictionary *temp;
    PRFileType fileType;
    File *file = [PRTagger fileAtURL:URL type:&fileType];
    switch (fileType) {
        case PRFileTypeAPE:
            temp = [PRTagger tagsForAPEFile:reinterpret_cast<APE::File *>(file)];
            break;
        case PRFileTypeASF:
            temp = [PRTagger tagsForASFFile:reinterpret_cast<ASF::File *>(file)];
            break;
        case PRFileTypeFLAC:
            temp = [PRTagger tagsForFLACFile:reinterpret_cast<FLAC::File *>(file)];
            break;
        case PRFileTypeMP4:
            temp = [PRTagger tagsForMP4File:reinterpret_cast<MP4::File *>(file)];
            break;
        case PRFileTypeMPC:
            temp = [PRTagger tagsForMPCFile:reinterpret_cast<MPC::File *>(file)];
            break;
        case PRFileTypeMPEG:
            temp = [PRTagger tagsForMPEGFile:reinterpret_cast<MPEG::File *>(file)];
            break;
        case PRFileTypeOggFLAC:
            temp = [PRTagger tagsForOggFLACFile:reinterpret_cast<Ogg::FLAC::File *>(file)];
            break;
        case PRFileTypeOggSpeex:
            temp = [PRTagger tagsForOggSpeexFile:reinterpret_cast<Ogg::Speex::File *>(file)];
            break;
        case PRFileTypeOggVorbis:
            temp = [PRTagger tagsForOggVorbisFile:reinterpret_cast<Ogg::Vorbis::File *>(file)];
            break;
        case PRFileTypeAIFF:
            temp = [PRTagger tagsForAIFFFile:reinterpret_cast<RIFF::AIFF::File *>(file)];
            break;
        case PRFileTypeWAV:
            temp = [PRTagger tagsForWAVFile:reinterpret_cast<RIFF::WAV::File *>(file)];
            break;
        case PRFileTypeTrueAudio:
            temp = [PRTagger tagsForTrueAudioFile:reinterpret_cast<TrueAudio::File *>(file)];
            break;
        case PRFileTypeWavPack:
            temp = [PRTagger tagsForWavPackFile:reinterpret_cast<WavPack::File *>(file)];
            break;
        case PRFileTypeUnknown:
        default:
            return nil;
            break;
    }
    delete file;
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:temp];
    for (NSNumber *i in [d allKeys]) {
        id value = [d objectForKey:i];
        switch ([i intValue]) {
            case PRTitleFileAttribute:
            case PRArtistFileAttribute:
            case PRAlbumFileAttribute:
            case PRComposerFileAttribute:
            case PRAlbumArtistFileAttribute:
            case PRGenreFileAttribute:
            case PRCommentsFileAttribute:
                if (![value isKindOfClass:[NSString class]] || [value length] > 255) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRBPMFileAttribute:
            case PRYearFileAttribute:
            case PRTrackCountFileAttribute:
            case PRTrackNumberFileAttribute:
            case PRDiscCountFileAttribute:
            case PRDiscNumberFileAttribute:
                if (![value isKindOfClass:[NSNumber class]] || [value intValue] > 9999 || [value intValue] < 0) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRAlbumArtFileAttribute:
                if (![value isKindOfClass:[NSData class]]) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRCompilationFileAttribute:
                if (![value isKindOfClass:[NSNumber class]] || [value intValue] > 1 || [value intValue] < 0) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRLyricsFileAttribute:
                if (![value isKindOfClass:[NSString class]] || [value length] > 10000) {
                    [d removeObjectForKey:i];
                }
                break;
            default:
                [d removeObjectForKey:i];
        }
    }
    
    NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithDictionary:[PRTagger defaultTags]];
    [tags addEntriesFromDictionary:d];
    NSString *path = [URL path];
	TagLib::FileRef fileRef([path UTF8String]);
	if(!fileRef.isNull() && fileRef.audioProperties()) {
		TagLib::AudioProperties *prop = fileRef.audioProperties();
        [tags setObject:[NSNumber numberWithInt:prop->length() * 1000]
                 forKey:[NSNumber numberWithInt:PRTimeFileAttribute]];
        [tags setObject:[NSNumber numberWithInt:prop->bitrate()]
                 forKey:[NSNumber numberWithInt:PRBitrateFileAttribute]];
        [tags setObject:[NSNumber numberWithInt:prop->sampleRate()]
                 forKey:[NSNumber numberWithInt:PRSampleRateFileAttribute]];
        [tags setObject:[NSNumber numberWithInt:prop->channels()]
                 forKey:[NSNumber numberWithInt:PRChannelsFileAttribute]];
	}
    NSData *checkSum = [PRTagger checkSumForFileAtPath:path];
    if (checkSum) {
        [tags setObject:checkSum forKey:[NSNumber numberWithInt:PRCheckSumFileAttribute]];
    }
    NSNumber *size = [PRTagger sizeForFileAtPath:path];
    if (size) {
        [tags setObject:size forKey:[NSNumber numberWithInt:PRSizeFileAttribute]];
    }
    NSDate *lastModified = [PRTagger lastModifiedForFileAtPath:path];
    if (lastModified) {
        [tags setObject:[lastModified description] forKey:[NSNumber numberWithInt:PRLastModifiedFileAttribute]];
    }
    [tags setObject:[NSNumber numberWithInt:fileType] forKey:[NSNumber numberWithInt:PRKindFileAttribute]];
    [tags setObject:[URL absoluteString] forKey:[NSNumber numberWithInt:PRPathFileAttribute]];
    return tags;
}

+ (NSDictionary *)simpleTagsForURL:(NSURL *)URL
{
    NSDictionary *temp;
    PRFileType fileType;
    File *file = [PRTagger fileAtURL:URL type:&fileType];
    switch (fileType) {
        case PRFileTypeAPE:
            temp = [PRTagger tagsForAPEFile:reinterpret_cast<APE::File *>(file)];
            break;
        case PRFileTypeASF:
            temp = [PRTagger tagsForASFFile:reinterpret_cast<ASF::File *>(file)];
            break;
        case PRFileTypeFLAC:
            temp = [PRTagger tagsForFLACFile:reinterpret_cast<FLAC::File *>(file)];
            break;
        case PRFileTypeMP4:
            temp = [PRTagger tagsForMP4File:reinterpret_cast<MP4::File *>(file)];
            break;
        case PRFileTypeMPC:
            temp = [PRTagger tagsForMPCFile:reinterpret_cast<MPC::File *>(file)];
            break;
        case PRFileTypeMPEG:
            temp = [PRTagger tagsForMPEGFile:reinterpret_cast<MPEG::File *>(file)];
            break;
        case PRFileTypeOggFLAC:
            temp = [PRTagger tagsForOggFLACFile:reinterpret_cast<Ogg::FLAC::File *>(file)];
            break;
        case PRFileTypeOggSpeex:
            temp = [PRTagger tagsForOggSpeexFile:reinterpret_cast<Ogg::Speex::File *>(file)];
            break;
        case PRFileTypeOggVorbis:
            temp = [PRTagger tagsForOggVorbisFile:reinterpret_cast<Ogg::Vorbis::File *>(file)];
            break;
        case PRFileTypeAIFF:
            temp = [PRTagger tagsForAIFFFile:reinterpret_cast<RIFF::AIFF::File *>(file)];
            break;
        case PRFileTypeWAV:
            temp = [PRTagger tagsForWAVFile:reinterpret_cast<RIFF::WAV::File *>(file)];
            break;
        case PRFileTypeTrueAudio:
            temp = [PRTagger tagsForTrueAudioFile:reinterpret_cast<TrueAudio::File *>(file)];
            break;
        case PRFileTypeWavPack:
            temp = [PRTagger tagsForWavPackFile:reinterpret_cast<WavPack::File *>(file)];
            break;
        case PRFileTypeUnknown:
        default:
            return nil;
            break;
    }
    delete file;
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:temp];
    for (NSNumber *i in [d allKeys]) {
        id value = [d objectForKey:i];
        switch ([i intValue]) {
            case PRTitleFileAttribute:
            case PRArtistFileAttribute:
            case PRAlbumFileAttribute:
            case PRComposerFileAttribute:
            case PRAlbumArtistFileAttribute:
            case PRGenreFileAttribute:
            case PRCommentsFileAttribute:
                if (![value isKindOfClass:[NSString class]] || [value length] > 255) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRBPMFileAttribute:
            case PRYearFileAttribute:
            case PRTrackCountFileAttribute:
            case PRTrackNumberFileAttribute:
            case PRDiscCountFileAttribute:
            case PRDiscNumberFileAttribute:
                if (![value isKindOfClass:[NSNumber class]] || [value intValue] > 9999 || [value intValue] < 0) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRAlbumArtFileAttribute:
                if (![value isKindOfClass:[NSData class]]) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRCompilationFileAttribute:
                if (![value isKindOfClass:[NSNumber class]] || [value intValue] > 1 || [value intValue] < 0) {
                    [d removeObjectForKey:i];
                }
                break;
            case PRLyricsFileAttribute:
                if (![value isKindOfClass:[NSString class]] || [value length] > 10000) {
                    [d removeObjectForKey:i];
                }
                break;
            default:
                [d removeObjectForKey:i];
        }
    }
    
    NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithDictionary:[PRTagger defaultTags]];
    [tags addEntriesFromDictionary:d];
    return tags;
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr URL:(NSURL *)URL
{
    switch (attr) {
        case PRTitleFileAttribute:
        case PRArtistFileAttribute:
        case PRAlbumFileAttribute:
        case PRComposerFileAttribute:
        case PRAlbumArtistFileAttribute:
        case PRGenreFileAttribute:
        case PRCommentsFileAttribute:
            if (![tag isKindOfClass:[NSString class]] || [tag length] > 255) {
                return;
            }
            break;
        case PRBPMFileAttribute:
        case PRYearFileAttribute:
        case PRTrackCountFileAttribute:
        case PRTrackNumberFileAttribute:
        case PRDiscCountFileAttribute:
        case PRDiscNumberFileAttribute:
            if (![tag isKindOfClass:[NSNumber class]] || [tag intValue] > 9999 || [tag intValue] < 0) {
                return;
            }
            break;
        case PRAlbumArtFileAttribute: {
            if (![tag isKindOfClass:[NSData class]]) {
                return;
            }
            NSImage *img = [[[NSImage alloc] initWithData:tag] autorelease];
            if (![img isValid]) {
                return;
            }
            tag = [NSBitmapImageRep representationOfImageRepsInArray:[img representations] usingType:NSPNGFileType properties:nil];
        }
            break;
        case PRCompilationFileAttribute:
            if (![tag isKindOfClass:[NSNumber class]] || [tag intValue] > 1 || [tag intValue] < 0) {
                return;
            }
            break;
        case PRLyricsFileAttribute:
            if (![tag isKindOfClass:[NSString class]] || [tag length] > 10000) {
                return;
            }
            break;
        default:
            return;
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

+ (NSDictionary *)defaultTags
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"", [NSNumber numberWithInt:PRTitleFileAttribute],
            @"", [NSNumber numberWithInt:PRArtistFileAttribute], 
            @"", [NSNumber numberWithInt:PRAlbumFileAttribute],
            @"", [NSNumber numberWithInt:PRComposerFileAttribute],
            @"", [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
            @"", [NSNumber numberWithInt:PRGenreFileAttribute],
            @"", [NSNumber numberWithInt:PRCommentsFileAttribute],
            @"", [NSNumber numberWithInt:PRLyricsFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRBPMFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRYearFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRTrackCountFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRTrackNumberFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRDiscNumberFileAttribute],
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRDiscCountFileAttribute], 
            [NSNumber numberWithInt:0], [NSNumber numberWithInt:PRCompilationFileAttribute],
            nil];
}

// ========================================
// Tags Priv
// ========================================

+ (File *)fileAtURL:(NSURL *)URL type:(PRFileType *)fileType
{
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
    } else if ([pathExtension compare:@"ASF"] == NSOrderedSame ||
               [pathExtension compare:@"WMA"] == NSOrderedSame) {
        file = new ASF::File([path UTF8String]);
        if (file->isValid()) {
            *fileType = PRFileTypeASF;
            return file;
        }
        delete file;
        return nil;
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

// ========================================
// Properties
// ========================================

+ (NSDate *)lastModifiedAtURL:(NSURL *)URL
{
    return [PRTagger lastModifiedForFileAtPath:[URL path]];
}

+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    if (fileAttributes) {
        return [fileAttributes objectForKey:NSFileModificationDate];
    }
    return nil;
}

+ (NSData *)checkSumForFileAtPath:(NSString *)path
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fileHandle) {
        NSData *firstMegabyte = [fileHandle readDataOfLength:10000];
        return [SSCrypto getMD5ForData:firstMegabyte];
    }
    return nil;
}

+ (NSNumber *)sizeForFileAtPath:(NSString *)path
{
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

// ========================================
// Tag Reading Priv
// ========================================

+ (NSDictionary *)tagsForAPEFile:(APE::File *)file
{
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

+ (NSDictionary *)tagsForASFFile:(ASF::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ASF::Tag *ASFTag = file->tag();
    if (ASFTag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForASFTag:ASFTag]];
    }
    return tags;
}

+ (NSDictionary *)tagsForFLACFile:(FLAC::File *)file
{
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
        [tags setObject:data forKey:[NSNumber numberWithInt:PRAlbumArtFileAttribute]];
    }
    return tags;
}

+ (NSDictionary *)tagsForMP4File:(MP4::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    MP4::Tag *MP4Tag = file->tag();
    if (MP4Tag) {
        [tags addEntriesFromDictionary:[[self class] tagsForMP4Tag:MP4Tag]];
    }
    return tags;
}

+ (NSDictionary *)tagsForMPCFile:(MPC::File *)file
{
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

+ (NSDictionary *)tagsForMPEGFile:(MPEG::File *)file
{
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

+ (NSDictionary *)tagsForOggFLACFile:(Ogg::FLAC::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;
}

+ (NSDictionary *)tagsForOggVorbisFile:(Ogg::Vorbis::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;
}

+ (NSDictionary *)tagsForOggSpeexFile:(Ogg::Speex::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    Ogg::XiphComment *xiphComment = file->tag();
    if (xiphComment) {
        [tags addEntriesFromDictionary:[PRTagger tagsForXiphComment:xiphComment]];
    }
    return tags;  
}

+ (NSDictionary *)tagsForAIFFFile:(RIFF::AIFF::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v2::Tag *ID3v2Tag = file->tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    return tags;
}

+ (NSDictionary *)tagsForWAVFile:(RIFF::WAV::File *)file
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    ID3v2::Tag *ID3v2Tag = file->tag();
    if (ID3v2Tag) {
        [tags addEntriesFromDictionary:[PRTagger tagsForID3v2Tag:ID3v2Tag]];
    }
    return tags;
}

+ (NSDictionary *)tagsForTrueAudioFile:(TrueAudio::File *)file
{
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

+ (NSDictionary *)tagsForWavPackFile:(WavPack::File *)file
{
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

+ (NSDictionary *)tagsForASFTag:(ASF::Tag *)tag
{
    ASF::AttributeListMap tagMap = tag->attributeListMap();
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    
    // String
    void (^readAttr)(PRFileAttribute attr, const char *name);
    readAttr = ^(PRFileAttribute attr, const char *name){
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTitleFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRTitleFileAttribute]);
    readAttr(PRArtistFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRArtistFileAttribute]);
    readAttr(PRAlbumFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRAlbumFileAttribute]);
    readAttr(PRAlbumArtistFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRAlbumArtistFileAttribute]);
    readAttr(PRComposerFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRComposerFileAttribute]);
    readAttr(PRGenreFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRGenreFileAttribute]);
    readAttr(PRCommentsFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRCommentsFileAttribute]);
    readAttr(PRLyricsFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRLyricsFileAttribute]);
    
    // Number
    readAttr = ^(PRFileAttribute attr, const char *name){
        if (!tagMap.contains(name)) {return;}
        NSNumber *number = [NSNumber numberWithInt:tagMap[name][0].toString().toInt()];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRBPMFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRBPMFileAttribute]);
    readAttr(PRYearFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRYearFileAttribute]);
    readAttr(PRTrackNumberFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRTrackNumberFileAttribute]);
    readAttr(PRTrackCountFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRTrackCountFileAttribute]);
    
    // Number 1
    readAttr = ^(PRFileAttribute attr, const char *name){
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:0] intValue]] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRDiscNumberFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRDiscNumberFileAttribute]);
    
    // Number 2
    readAttr = ^(PRFileAttribute attr, const char *name){
        if (!tagMap.contains(name)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[name][0].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:1] intValue]] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRDiscCountFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRDiscCountFileAttribute]);
    
    // Artwork
    readAttr = ^(PRFileAttribute attr, const char *name){
        if (!tagMap.contains(name)) {return;}
        NSData *data = [NSData dataWithBytes:tagMap["WM/Picture"][0].toByteVector().data() 
                                      length:tagMap["WM/Picture"][0].toByteVector().size()];
        [tags setObject:data forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRAlbumArtFileAttribute, [PRTagger ASFAttributeNameForAttribute:PRAlbumArtFileAttribute]);
    return tags;
}

+ (NSDictionary *)tagsForMP4Tag:(MP4::Tag *)tag
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    MP4::ItemListMap items = tag->itemListMap();
    
//    MP4::ItemListMap::ConstIterator it = tags.begin();
//    for (; it != tags.end(); it++) {
//        cout << (*it).first << " - \"" << (*it).second.toStringList() << " Int:" << (*it).second.toInt() << "\"" << endl;
//    }
    
    // Genre
    void (^readAttr)(PRFileAttribute attr, const char *code);
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toInt()];
        NSString *string = [PRTagger genreForID3Genre:[number stringValue]];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRGenreFileAttribute, "gnre");
    
    // String
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSString *string = [NSString stringWithUTF8String:items[code].toStringList().toString(", ").toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTitleFileAttribute, [PRTagger MP4CodeForAttribute:PRTitleFileAttribute]);
    readAttr(PRArtistFileAttribute, [PRTagger MP4CodeForAttribute:PRArtistFileAttribute]);
    readAttr(PRAlbumFileAttribute, [PRTagger MP4CodeForAttribute:PRAlbumFileAttribute]);
    readAttr(PRAlbumArtistFileAttribute, [PRTagger MP4CodeForAttribute:PRAlbumArtistFileAttribute]);
    readAttr(PRComposerFileAttribute, [PRTagger MP4CodeForAttribute:PRComposerFileAttribute]);
    readAttr(PRGenreFileAttribute, [PRTagger MP4CodeForAttribute:PRGenreFileAttribute]);
    readAttr(PRCommentsFileAttribute, [PRTagger MP4CodeForAttribute:PRCommentsFileAttribute]);
    readAttr(PRLyricsFileAttribute, [PRTagger MP4CodeForAttribute:PRLyricsFileAttribute]);
    
    // Number as String
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toStringList().toString().toInt()];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRYearFileAttribute, [PRTagger MP4CodeForAttribute:PRYearFileAttribute]);
    
    // Number
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toInt()];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRBPMFileAttribute, [PRTagger MP4CodeForAttribute:PRBPMFileAttribute]);
    readAttr(PRCompilationFileAttribute, [PRTagger MP4CodeForAttribute:PRCompilationFileAttribute]);
    
    // Number 1
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toIntPair().first];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRDiscNumberFileAttribute, [PRTagger MP4CodeForAttribute:PRDiscNumberFileAttribute]);
    readAttr(PRTrackNumberFileAttribute, [PRTagger MP4CodeForAttribute:PRTrackNumberFileAttribute]);
    
    // Number 1
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSNumber *number = [NSNumber numberWithInt:items[code].toIntPair().second];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRDiscCountFileAttribute, [PRTagger MP4CodeForAttribute:PRDiscCountFileAttribute]);
    readAttr(PRTrackCountFileAttribute, [PRTagger MP4CodeForAttribute:PRTrackCountFileAttribute]);

    // Artwork
    readAttr = ^(PRFileAttribute attr, const char *code){
        if (!items.contains(code)) {return;}
        NSData *data = [NSData dataWithBytes:items[code].toCoverArtList().front().data().data() 
                                      length:items[code].toCoverArtList().front().data().size()];
        [tags setObject:data forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRAlbumArtFileAttribute, [PRTagger MP4CodeForAttribute:PRAlbumArtFileAttribute]);
    return tags;
}

+ (NSDictionary *)tagsForID3v2Tag:(TagLib::ID3v2::Tag *)tag
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    
//    ID3v2::FrameList::ConstIterator it = tag->frameList().begin();
//    for(; it != tag->frameList().end(); it++) {
//        cout << (*it)->frameID() << " - \"" << (*it)->toString() << "\"" << endl;
//    }
    
    // String
    void (^readAttr)(PRFileAttribute attr, const char *frameID);
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTitleFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRTitleFileAttribute]);
    readAttr(PRArtistFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRArtistFileAttribute]);
    readAttr(PRAlbumFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRAlbumFileAttribute]);
    readAttr(PRAlbumArtistFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRAlbumArtistFileAttribute]);
    readAttr(PRComposerFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRComposerFileAttribute]);
    
    // Genre
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:[self genreForID3Genre:string] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRGenreFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRGenreFileAttribute]);
    
    // Comments
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        for (int i = 0; i < tag->frameListMap()[frameID].size(); i++) {
            ID3v2::CommentsFrame *frame = dynamic_cast<ID3v2::CommentsFrame *>(tag->frameListMap()[frameID][i]);
            if (!frame) {continue;}
            NSString *description = [NSString stringWithUTF8String:frame->description().toCString(TRUE)];
            if ([description isEqualToString:@"iTunes_CDDB_IDs"] || [description isEqualToString:@"iTunSMPB"] ||
                [description isEqualToString:@"iTunPGAP"] || [description isEqualToString:@"iTunNORM"]) {continue;}
            NSString *string = [NSString stringWithUTF8String:frame->toString().toCString(TRUE)];
            [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
            return;
        }
    };
    readAttr(PRCommentsFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRCommentsFileAttribute]);
    
    // Lyrics
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        ID3v2::UnsynchronizedLyricsFrame *frame = dynamic_cast<ID3v2::UnsynchronizedLyricsFrame *>(tag->frameListMap()[frameID].front());
        if (!frame) {return;}
        NSString *string = [NSString stringWithUTF8String:frame->toString().toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRLyricsFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRLyricsFileAttribute]);
    
    // Number
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        [tags setObject:[NSNumber numberWithInt:[string intValue]] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRYearFileAttribute, "TDAT");
    readAttr(PRYearFileAttribute, "YEAR");
    readAttr(PRYearFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRYearFileAttribute]);
    readAttr(PRBPMFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRBPMFileAttribute]);
    readAttr(PRCompilationFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRCompilationFileAttribute]);
    
    // Number 1
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:0] intValue]] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTrackNumberFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRTrackNumberFileAttribute]);
    readAttr(PRDiscNumberFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRDiscNumberFileAttribute]);
    
    // Number 2
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:tag->frameListMap()[frameID].front()->toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        [tags setObject:[NSNumber numberWithInt:[[array objectAtIndex:1] intValue]] forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTrackCountFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRTrackCountFileAttribute]);
    readAttr(PRDiscCountFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRDiscCountFileAttribute]);
    
    // Artwork
    readAttr = ^(PRFileAttribute attr, const char *frameID){
        if (tag->frameListMap()[frameID].isEmpty()) {return;}
        ID3v2::AttachedPictureFrame *frame = dynamic_cast<ID3v2::AttachedPictureFrame *>(tag->frameListMap()["APIC"].front());
        if (!frame) {return;}
        NSData *data = [NSData dataWithBytes:frame->picture().data() length:frame->picture().size()];
        [tags setObject:data forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRAlbumArtFileAttribute, [PRTagger ID3v2FrameIDForAttribute:PRAlbumArtFileAttribute]);
    
    return tags;
}

+ (NSDictionary *)tagsForID3v1Tag:(TagLib::ID3v1::Tag *)tag
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    NSString *stringValue;
    NSNumber *numberValue;
    stringValue = [NSString stringWithUTF8String:tag->title().toCString(TRUE)];
    [tags setObject:stringValue forKey:[NSNumber numberWithInt:PRTitleFileAttribute]];
    stringValue = [NSString stringWithUTF8String:tag->artist().toCString(TRUE)];
    [tags setObject:stringValue forKey:[NSNumber numberWithInt:PRArtistFileAttribute]];
    stringValue = [NSString stringWithUTF8String:tag->album().toCString(TRUE)];
    [tags setObject:stringValue forKey:[NSNumber numberWithInt:PRAlbumFileAttribute]];
    stringValue = [NSString stringWithUTF8String:tag->comment().toCString(TRUE)];
    [tags setObject:stringValue forKey:[NSNumber numberWithInt:PRCommentsFileAttribute]];
    numberValue = [NSNumber numberWithInt:tag->year()];
    [tags setObject:numberValue forKey:[NSNumber numberWithInt:PRYearFileAttribute]];
    numberValue = [NSNumber numberWithInt:tag->track()];
    [tags setObject:numberValue forKey:[NSNumber numberWithInt:PRTrackNumberFileAttribute]];
    stringValue = [NSString stringWithUTF8String:tag->genre().toCString(TRUE)];
    stringValue = [PRTagger genreForID3Genre:stringValue];
    [tags setObject:stringValue forKey:[NSNumber numberWithInt:PRGenreFileAttribute]];
    
//    NSLog(@"ID3v1:%@",tags);
    return tags;
}

+ (NSDictionary *)tagsForAPETag:(TagLib::APE::Tag *)tag
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    APE::ItemListMap itemListMap = tag->itemListMap();
    
//    APE::ItemListMap::ConstIterator it = itemListMap.begin();
//    for(; it != itemListMap.end(); it++) {
//        cout << (*it).first << ". - \"" << (*it).second.toString() << "\"" << endl;
//    }
    
    // String
    void (^readAttr)(PRFileAttribute attr, const char *key);
    readAttr = ^(PRFileAttribute attr, const char *key){
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTitleFileAttribute, [PRTagger APEKeyForAttribute:PRTitleFileAttribute]);
    readAttr(PRArtistFileAttribute, [PRTagger APEKeyForAttribute:PRArtistFileAttribute]);
    readAttr(PRAlbumFileAttribute, [PRTagger APEKeyForAttribute:PRAlbumFileAttribute]);
    readAttr(PRAlbumArtistFileAttribute, [PRTagger APEKeyForAttribute:PRAlbumArtistFileAttribute]);
    readAttr(PRComposerFileAttribute, [PRTagger APEKeyForAttribute:PRComposerFileAttribute]);
    readAttr(PRCommentsFileAttribute, [PRTagger APEKeyForAttribute:PRCommentsFileAttribute]);
    readAttr(PRLyricsFileAttribute, [PRTagger APEKeyForAttribute:PRLyricsFileAttribute]);
    readAttr(PRGenreFileAttribute, [PRTagger APEKeyForAttribute:PRGenreFileAttribute]);

    // Number
    readAttr = ^(PRFileAttribute attr, const char *key){
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSNumber *number = [NSNumber numberWithInt:[string intValue]];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRBPMFileAttribute, [PRTagger APEKeyForAttribute:PRBPMFileAttribute]);
    readAttr(PRYearFileAttribute, [PRTagger APEKeyForAttribute:PRYearFileAttribute]);
    readAttr(PRCompilationFileAttribute, [PRTagger APEKeyForAttribute:PRCompilationFileAttribute]);
    
    // Number 1
    readAttr = ^(PRFileAttribute attr, const char *key){
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        NSNumber *number = [NSNumber numberWithInt:[[array objectAtIndex:0] intValue]];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTrackNumberFileAttribute, [PRTagger APEKeyForAttribute:PRTrackNumberFileAttribute]);
    readAttr(PRDiscNumberFileAttribute, [PRTagger APEKeyForAttribute:PRDiscNumberFileAttribute]);
    
    // Number 2
    readAttr = ^(PRFileAttribute attr, const char *key){
        if (itemListMap[key].isEmpty()) {return;}
        NSString *string = [NSString stringWithUTF8String:itemListMap[key].toString().toCString(TRUE)];
        NSArray *array = [string componentsSeparatedByString:@"/"];
        if ([array count] < 2) {return;}
        NSNumber *number = [NSNumber numberWithInt:[[array objectAtIndex:1] intValue]];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTrackCountFileAttribute, [PRTagger APEKeyForAttribute:PRTrackCountFileAttribute]);
    readAttr(PRDiscCountFileAttribute, [PRTagger APEKeyForAttribute:PRDiscCountFileAttribute]);    
    return tags;
}

+ (NSDictionary *)tagsForXiphComment:(TagLib::Ogg::XiphComment *)tag;
{
    NSMutableDictionary *tags = [NSMutableDictionary dictionary];
    TagLib::Ogg::FieldListMap tagMap = tag->fieldListMap();
    
//    TagLib::Ogg::FieldListMap::ConstIterator it = tagMap.begin();
//    for(; it != tagMap.end(); it++) {
//        NSLog(@"key:%s field:%s",(*it).first.toCString(TRUE),(*it).second.toString().toCString(TRUE));
//    }
    
    // String
    void (^readAttr)(PRFileAttribute attr, const char *field);
    readAttr = ^(PRFileAttribute attr, const char *field){
        if (!tagMap.contains(field)) {return;}
        NSString *string = [NSString stringWithUTF8String:tagMap[field].front().toCString(TRUE)];
        [tags setObject:string forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRTitleFileAttribute, [PRTagger XiphFieldNameForAttribute:PRTitleFileAttribute]);
    readAttr(PRArtistFileAttribute, [PRTagger XiphFieldNameForAttribute:PRArtistFileAttribute]);
    readAttr(PRAlbumFileAttribute, [PRTagger XiphFieldNameForAttribute:PRAlbumFileAttribute]);
    readAttr(PRAlbumArtistFileAttribute, [PRTagger XiphFieldNameForAttribute:PRAlbumArtistFileAttribute]);
    readAttr(PRComposerFileAttribute, [PRTagger XiphFieldNameForAttribute:PRComposerFileAttribute]);
    readAttr(PRGenreFileAttribute, [PRTagger XiphFieldNameForAttribute:PRGenreFileAttribute]);
    readAttr(PRCommentsFileAttribute, [PRTagger XiphFieldNameForAttribute:PRCommentsFileAttribute]);
    readAttr(PRLyricsFileAttribute, [PRTagger XiphFieldNameForAttribute:PRLyricsFileAttribute]);
    
    readAttr = ^(PRFileAttribute attr, const char *field){
        if (!tagMap.contains(field)) {return;}
        NSNumber *number = [NSNumber numberWithInt:tagMap[field].front().stripWhiteSpace().toInt()];
        [tags setObject:number forKey:[NSNumber numberWithInt:attr]];
    };
    readAttr(PRYearFileAttribute, [PRTagger XiphFieldNameForAttribute:PRYearFileAttribute]);
    readAttr(PRBPMFileAttribute, [PRTagger XiphFieldNameForAttribute:PRBPMFileAttribute]);
    readAttr(PRTrackNumberFileAttribute, [PRTagger XiphFieldNameForAttribute:PRTrackNumberFileAttribute]);
    readAttr(PRTrackCountFileAttribute, [PRTagger XiphFieldNameForAttribute:PRTrackCountFileAttribute]);
    readAttr(PRDiscNumberFileAttribute, [PRTagger XiphFieldNameForAttribute:PRDiscNumberFileAttribute]);
    readAttr(PRDiscCountFileAttribute, [PRTagger XiphFieldNameForAttribute:PRDiscCountFileAttribute]);
    readAttr(PRCompilationFileAttribute, [PRTagger XiphFieldNameForAttribute:PRCompilationFileAttribute]);

    return tags;    
}

// ========================================
// Tag Writing Priv
// ========================================

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr APEFile:(APE::File *)file
{
    ID3v1::Tag *ID3v1Tag = file->ID3v1Tag();
    if (ID3v1Tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1Tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[[self class] setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ASFFile:(ASF::File *)file
{
    ASF::Tag *ASFTag = file->tag();
    if (ASFTag) {
        [[self class] setTag:tag forAttribute:attr ASFTag:ASFTag];
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr FLACFile:(FLAC::File *)file
{
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag();
	if (ID3v2tag) {
		[[self class] setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
    TagLib::Ogg::XiphComment *xiphComment = file->xiphComment(TRUE);
	if (xiphComment) {
		[[self class] setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
    
    if (attr == PRAlbumArtFileAttribute) {
        file->removePictures();
        NSData *data = tag;
        if ([data length] != 0) {
            FLAC::Picture *p = new FLAC::Picture();
            p->setData(ByteVector((const char *)[data bytes], [data length]));
            file->addPicture(p);
        }
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MP4File:(MP4::File *)file
{
    MP4::Tag *MP4Tag = file->tag();
    if (MP4Tag) {
        [[self class] setTag:tag forAttribute:attr MP4Tag:MP4Tag];
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MPCFile:(MPC::File *)file
{
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[[self class] setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MPEGFile:(MPEG::File *)file
{
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag(TRUE);
	if (ID3v2tag) {
		[[self class] setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
	APE::Tag *APETag = file->APETag();
	if (APETag) {
		[[self class] setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggFLACFile:(Ogg::FLAC::File *)file
{
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[[self class] setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggVorbisFile:(Ogg::Vorbis::File *)file
{
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[[self class] setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr OggSpeexFile:(Ogg::Speex::File *)file
{
    TagLib::Ogg::XiphComment *xiphComment = file->tag();
	if (xiphComment) {
		[[self class] setTag:tag forAttribute:attr XiphComment:xiphComment];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr AIFFFile:(RIFF::AIFF::File *)file
{
    TagLib::ID3v2::Tag *ID3v2tag = file->tag();
	if (ID3v2tag) {
		[[self class] setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr WAVFile:(RIFF::WAV::File *)file
{
    TagLib::ID3v2::Tag *ID3v2tag = file->tag();
	if (ID3v2tag) {
		[[self class] setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr TrueAudioFile:(TrueAudio::File *)file
{
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	TagLib::ID3v2::Tag *ID3v2tag = file->ID3v2Tag(TRUE);
	if (ID3v2tag) {
		[[self class] setTag:tag forAttribute:attr ID3v2Tag:ID3v2tag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr WavPackFile:(WavPack::File *)file
{
    TagLib::ID3v1::Tag *ID3v1tag = file->ID3v1Tag();
    if (ID3v1tag) {
        [[self class] setTag:tag forAttribute:attr ID3v1Tag:ID3v1tag];
    }
	APE::Tag *APETag = file->APETag(TRUE);
	if (APETag) {
		[[self class] setTag:tag forAttribute:attr APETag:APETag];
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ASFTag:(ASF::Tag *)ASFTag
{
    ASF::AttributeListMap &attributeListMap = ASFTag->attributeListMap();
    const char *ASFAttributeName = [[self class] ASFAttributeNameForAttribute:attr];
    ASF::Attribute ASFAttribute;
    bool isAttr = FALSE;
	switch (attr) {
		case PRTitleFileAttribute:
		case PRArtistFileAttribute:
		case PRAlbumFileAttribute:
		case PRComposerFileAttribute:
		case PRAlbumArtistFileAttribute:
        case PRCommentsFileAttribute:
        case PRGenreFileAttribute:
        case PRYearFileAttribute:
        case PRBPMFileAttribute:
        case PRLyricsFileAttribute:
            if ([tag count] == 0) {
                ASFAttribute = String([tag UTF8String], String::UTF8);
                isAttr = TRUE;
            }
			break;
		case PRTrackNumberFileAttribute:
        case PRDiscNumberFileAttribute: {
            int secondaryValue = 0;
            if (attributeListMap.contains(ASFAttributeName) && attributeListMap[ASFAttributeName].size() > 0) {
                secondaryValue = [[self class] secondValue:attributeListMap[ASFAttributeName][0].toString().toCString(TRUE)];
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
        }
			break;
		case PRTrackCountFileAttribute:
        case PRDiscCountFileAttribute: {
            int secondaryValue = 0;
            if (attributeListMap.contains(ASFAttributeName) && attributeListMap[ASFAttributeName].size() > 0) {
                secondaryValue = [[self class] secondValue:attributeListMap[ASFAttributeName][0].toString().toCString(TRUE)];
            }
            if (secondaryValue != 0 && [tag intValue] == 0) {
                tag = [NSString stringWithFormat:@"%d", secondaryValue, tag];
                ASFAttribute = String([tag UTF8String], String::UTF8);
                isAttr = TRUE;
            } else if ([tag intValue] != 0) {
                tag = [NSString stringWithFormat:@"%.1d/%@", secondaryValue, tag];
                ASFAttribute = String([tag UTF8String], String::UTF8);
                isAttr = TRUE;
            }
            ASFTag->removeItem("WM/Track");
        }
			break;
		case PRAlbumArtFileAttribute: {
            NSData *data = tag;
            if ([data length] != 0) {
                ASF::Picture p;
                p.setPicture(ByteVector((char *)[data bytes], [data length]));
                ASFAttribute = ASF::Attribute(p);
                isAttr = TRUE;
            }
        }            
			break;
		default:
            return;
	}
    
    if (isAttr) {
        ASFTag->setAttribute(ASFAttributeName, ASFAttribute);
    } else {
        ASFTag->removeItem(ASFAttributeName);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr MP4Tag:(MP4::Tag *)MP4Tag
{
    MP4::ItemListMap &itemListMap = MP4Tag->itemListMap();
    const char *MP4Code = [[self class] MP4CodeForAttribute:attr];
    MP4::Item item;
    bool isItem = FALSE;
	switch (attr) {
		case PRTitleFileAttribute:
		case PRArtistFileAttribute:
		case PRAlbumFileAttribute:
		case PRComposerFileAttribute:
		case PRAlbumArtistFileAttribute:
        case PRCommentsFileAttribute:
        case PRLyricsFileAttribute:
            if ([tag length] != 0) {
                item = StringList(String([tag UTF8String], String::UTF8));
                isItem = TRUE;
            }
			break;
        case PRGenreFileAttribute: // Genre is either '©gen' or 'gnre' so have to remove 'gnre' tag
            if ([tag length] != 0) {
                item = StringList(String([tag UTF8String], String::UTF8));
                isItem = TRUE;
            }
            itemListMap.erase("gnre");
			break;
        case PRYearFileAttribute:
            tag = [tag stringValue];
            if ([tag length] != 0) {
                item = StringList(String([tag UTF8String], String::UTF8));
                isItem = TRUE;
            }
			break;
        case PRCompilationFileAttribute:
		case PRBPMFileAttribute:
            if ([tag intValue] != 0) {
                item = [tag intValue];
                isItem = TRUE;
            }
			break;
		case PRTrackNumberFileAttribute:
        case PRDiscNumberFileAttribute: {
            int secondaryNumber = 0;
            if (itemListMap.contains(MP4Code)) {
                secondaryNumber = itemListMap[MP4Code].toIntPair().second;
            }
            if (secondaryNumber != 0 || [tag intValue] != 0) {
                item = MP4::Item([tag intValue], secondaryNumber);
                isItem = TRUE;
            }
        }
			break;
		case PRTrackCountFileAttribute:
        case PRDiscCountFileAttribute: {
            int secondaryNumber = 0;
            if (itemListMap.contains(MP4Code)) {
                secondaryNumber = itemListMap[MP4Code].toIntPair().first;
            }
            if (secondaryNumber != 0 || [tag intValue] != 0) {
                item = MP4::Item(secondaryNumber, [tag intValue]);
                isItem = TRUE;
            }
        }
            break;
		case PRAlbumArtFileAttribute: {
            NSData *data = tag;
            if ([data length] != 0) {
                MP4::CoverArtList list;
                list.append(MP4::CoverArt(MP4::CoverArt::PNG, ByteVector((char *)[data bytes], [data length])));
                item = MP4::Item(list);
                isItem = TRUE;
            }
        }
			break;
		default:
			return;
	}
    
    if (isItem) {
        itemListMap.insert(MP4Code, item);
    } else {
        itemListMap.erase(MP4Code);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ID3v2Tag:(ID3v2::Tag *)id3v2tag
{
	TagLib::ID3v2::FrameListMap frameListMap = id3v2tag->frameListMap();
	const char *frameID = [[self class] ID3v2FrameIDForAttribute:attr];
    ID3v2::Frame *frame = NULL;
	switch (attr) {
		case PRTitleFileAttribute:
		case PRArtistFileAttribute:
		case PRAlbumFileAttribute:
		case PRComposerFileAttribute:
		case PRAlbumArtistFileAttribute:
		case PRGenreFileAttribute:
            if ([tag length] != 0) {
                ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
                f->setText(TagLib::String([tag UTF8String], String::UTF8));
                frame = f;
            }
            break;
        case PRCommentsFileAttribute:{
            id3v2tag->removeFrames(frameID);
            if ([tag length] != 0) {
                ID3v2::CommentsFrame *f = new ID3v2::CommentsFrame(String::UTF8);
                f->setText(TagLib::String([tag UTF8String], String::UTF8));
                f->setLanguage(ByteVector("eng", 3));
                frame = f;
            }
            break;
        }
        case PRLyricsFileAttribute:
            id3v2tag->removeFrames(frameID);
            if ([tag length] != 0) {
                ID3v2::UnsynchronizedLyricsFrame *f = new ID3v2::UnsynchronizedLyricsFrame(String::UTF8);
                f->setText(TagLib::String([tag UTF8String], String::UTF8));
                f->setLanguage(ByteVector("eng", 3));
                frame = f;
            }
            break;
		case PRBPMFileAttribute:
		case PRYearFileAttribute:
        case PRCompilationFileAttribute:
            if ([tag intValue] != 0) {
                tag = [tag stringValue];
                ID3v2::TextIdentificationFrame *f = new ID3v2::TextIdentificationFrame(frameID, String::UTF8);
                f->setText(TagLib::String([tag UTF8String], String::UTF8));
                frame = f;
            }
			break;
		case PRTrackNumberFileAttribute:
		case PRDiscNumberFileAttribute: {
            int secondaryValue = 0;
            if (attr == PRTrackNumberFileAttribute) {
                secondaryValue = [[[[self class] tagsForID3v2Tag:id3v2tag] objectForKey:[NSNumber numberWithInt:PRTrackCountFileAttribute]] intValue];
            } else if (attr == PRDiscNumberFileAttribute) {
                secondaryValue = [[[[self class] tagsForID3v2Tag:id3v2tag] objectForKey:[NSNumber numberWithInt:PRDiscCountFileAttribute]] intValue];
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
        }
			break;
		case PRTrackCountFileAttribute:
		case PRDiscCountFileAttribute: {
            int secondaryValue = 0;
            if (attr == PRTrackCountFileAttribute) {
                secondaryValue = [[[[self class] tagsForID3v2Tag:id3v2tag] objectForKey:[NSNumber numberWithInt:PRTrackNumberFileAttribute]] intValue];
            } else if (attr == PRDiscCountFileAttribute) {
                secondaryValue = [[[[self class] tagsForID3v2Tag:id3v2tag] objectForKey:[NSNumber numberWithInt:PRDiscNumberFileAttribute]] intValue];
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
        }
			break;
		case PRAlbumArtFileAttribute: {
            NSData *data = tag;
            if ([data length] != 0) {
                ID3v2::AttachedPictureFrame *f = new ID3v2::AttachedPictureFrame();
                f->setPicture(ByteVector((const char *)[data bytes], [data length]));
                frame = f;
            }
        }
			break;
		default:
			return;
	}
    
    id3v2tag->removeFrames(frameID);
    if (frame) {
		id3v2tag->addFrame(frame);
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr ID3v1Tag:(ID3v1::Tag *)id3v1tag
{
    int intValue;
    String stringValue;
    if ([tag isKindOfClass:[NSNumber class]]) {
        intValue = [tag intValue];
    } else if ([tag isKindOfClass:[NSString class]]) {
        if (attr == PRGenreFileAttribute) {
            tag = [[self class] ID3GenreForGenre:tag];
        }
        stringValue = String([tag UTF8String], String::UTF8);
    }
    
    switch (attr) {
        case PRTitleFileAttribute:
            id3v1tag->setTitle(stringValue);
            break;
        case PRAlbumFileAttribute:
            id3v1tag->setAlbum(stringValue);
            break;
        case PRArtistFileAttribute:
            id3v1tag->setArtist(stringValue);
            break;
        case PRCommentsFileAttribute:
            id3v1tag->setComment(stringValue);
            break;
        case PRGenreFileAttribute:
            id3v1tag->setGenre(stringValue);
            break;
        case PRYearFileAttribute:
            id3v1tag->setYear(intValue);
            break;
        case PRTrackNumberFileAttribute:
            id3v1tag->setTrack(intValue);
            break;
        default:
            break;
    }
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr APETag:(APE::Tag *)apeTag
{
    const APE::ItemListMap &itemListMap = apeTag->itemListMap();
    const char *APEKey = [[self class] APEKeyForAttribute:attr];
    APE::Item item;
	switch (attr) {
		case PRTitleFileAttribute:
		case PRArtistFileAttribute:
		case PRAlbumFileAttribute:
		case PRComposerFileAttribute:
		case PRAlbumArtistFileAttribute:
        case PRCommentsFileAttribute:
        case PRGenreFileAttribute:
        case PRLyricsFileAttribute:
            if ([tag length] > 0) {
                item = APE::Item(APEKey, String([tag UTF8String], String::UTF8));
                apeTag->setItem(APEKey, item);
            } else {
                apeTag->removeItem(APEKey);
            }
			break;
		case PRBPMFileAttribute:
		case PRYearFileAttribute:
        case PRCompilationFileAttribute:
            if ([tag intValue] != 0) {
                item = APE::Item(APEKey, String([[tag stringValue] UTF8String], String::UTF8));
                apeTag->setItem(APEKey, item);
            } else {
                apeTag->removeItem(APEKey);
            }
			break;
		case PRTrackNumberFileAttribute:
        case PRDiscNumberFileAttribute: {
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
        }
			break;
		case PRTrackCountFileAttribute:
		case PRDiscCountFileAttribute: {
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
            break;
		default:
			return;
	}
}

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr XiphComment:(Ogg::XiphComment *)xiphComment
{
    const char *fieldName = [[self class] XiphFieldNameForAttribute:attr];
	switch (attr) {
		case PRTitleFileAttribute:
		case PRArtistFileAttribute:
		case PRAlbumFileAttribute:
		case PRComposerFileAttribute:
		case PRAlbumArtistFileAttribute:
        case PRCommentsFileAttribute:
		case PRGenreFileAttribute:
        case PRLyricsFileAttribute:
            if ([tag length] != 0) {
                xiphComment->addField(fieldName, TagLib::String([tag UTF8String], TagLib::String::UTF8), TRUE);
            } else {
                xiphComment->removeField(fieldName);
            }
            break;
		case PRBPMFileAttribute:
		case PRYearFileAttribute:
		case PRTrackNumberFileAttribute:
		case PRTrackCountFileAttribute:
		case PRDiscNumberFileAttribute:
		case PRDiscCountFileAttribute:
        case PRCompilationFileAttribute:
            if ([tag intValue] != 0) {
                xiphComment->addField(fieldName, TagLib::String([[tag stringValue] UTF8String], TagLib::String::UTF8), TRUE);
            } else {
                xiphComment->removeField(fieldName);
            }
			break;
		default:
			break;
	}
}

// ========================================
// Tag Miscellaneous
// ========================================

+ (int)firstValue:(const char *)string
{
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

+ (int)secondValue:(const char *)string
{
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

+ (const char *)ID3v2FrameIDForAttribute:(PRFileAttribute)attribute
{
	switch (attribute) {
		case PRTitleFileAttribute:
			return "TIT2";
		case PRArtistFileAttribute:
			return "TPE1";
		case PRAlbumFileAttribute:
			return "TALB";
		case PRComposerFileAttribute:
			return "TCOM";
		case PRAlbumArtistFileAttribute:
			return "TPE2";	
		case PRBPMFileAttribute:
			return "TBPM";
		case PRYearFileAttribute:
			return "TDRC";
		case PRTrackNumberFileAttribute:
		case PRTrackCountFileAttribute:
            return "TRCK";
		case PRDiscNumberFileAttribute:
		case PRDiscCountFileAttribute:
            return "TPOS";
		case PRCommentsFileAttribute:
			return "COMM";
		case PRGenreFileAttribute:
			return "TCON";
		case PRAlbumArtFileAttribute:
			return "APIC";
        case PRCompilationFileAttribute:
            return "TCMP";
        case PRLyricsFileAttribute:
            return "USLT";
		default:
			return "";
	}
}

+ (const char *)ASFAttributeNameForAttribute:(PRFileAttribute)attribute
{
    switch (attribute) {
		case PRTitleFileAttribute:
            return "Title";
		case PRArtistFileAttribute:
            return "Author";
		case PRAlbumFileAttribute:
            return "WM/AlbumTitle";
		case PRComposerFileAttribute:
            return "WM/Composer";
		case PRAlbumArtistFileAttribute:
            return "WM/AlbumArtist";
		case PRBPMFileAttribute:
            return "WM/BeatsPerMinute";
		case PRYearFileAttribute:
            return "WM/Year";
		case PRTrackNumberFileAttribute:
		case PRTrackCountFileAttribute:
            return "WM/TrackNumber";
		case PRDiscNumberFileAttribute:
		case PRDiscCountFileAttribute:
            return "WM/PartOfSet";
		case PRCommentsFileAttribute:
            return "WM/Comments";
		case PRGenreFileAttribute:
            return "WM/Genre";
		case PRAlbumArtFileAttribute:
            return "WM/Picture";
        case PRLyricsFileAttribute:
            return "WM/Lyrics";
        default:
            return "";
    }
}

+ (const char *)APEKeyForAttribute:(PRFileAttribute)attribute
{
    switch (attribute) {
		case PRTitleFileAttribute:
            return "TITLE";
		case PRArtistFileAttribute:
            return "ARTIST";
		case PRAlbumFileAttribute:
            return "ALBUM";
		case PRComposerFileAttribute:
            return "COMPOSER";
		case PRAlbumArtistFileAttribute:
            return "ALBUMARTIST";
		case PRBPMFileAttribute:
            return "BPM";
		case PRYearFileAttribute:
            return "YEAR";
		case PRTrackNumberFileAttribute:
		case PRTrackCountFileAttribute:
            return "TRACK";
		case PRDiscNumberFileAttribute:
		case PRDiscCountFileAttribute:
            return "MEDIA";
		case PRCommentsFileAttribute:
            return "COMMENT";
		case PRGenreFileAttribute:
            return "GENRE";
        case PRLyricsFileAttribute:
            return "LYRICS";
        case PRCompilationFileAttribute:
            return "COMPILATION";
        default:
            return "";
    }
}

+ (const char *)MP4CodeForAttribute:(PRFileAttribute)attribute
{
    switch (attribute) {
		case PRTitleFileAttribute:
            return "\251nam";
		case PRArtistFileAttribute:
            return "\251ART";
		case PRAlbumFileAttribute:
            return "\251alb";
		case PRComposerFileAttribute:
            return "\251wrt";
		case PRAlbumArtistFileAttribute:
            return "aART";	
		case PRBPMFileAttribute:
            return "tmpo";
		case PRYearFileAttribute:
            return "\251day";
		case PRTrackNumberFileAttribute:
		case PRTrackCountFileAttribute:
            return "trkn";
		case PRDiscNumberFileAttribute:
		case PRDiscCountFileAttribute:
            return "disk";
		case PRCommentsFileAttribute:
            return "\251cmt";
		case PRGenreFileAttribute:
            return "\251gen";
		case PRAlbumArtFileAttribute:
            return "covr";
        case PRCompilationFileAttribute:
            return "cpil";
        case PRLyricsFileAttribute:
            return "\251lyr";
        default:
            return "";
    }
}

+ (const char *)XiphFieldNameForAttribute:(PRFileAttribute)attribute
{
    switch (attribute) {
		case PRTitleFileAttribute:
			return "TITLE";
		case PRArtistFileAttribute:
			return "ARTIST";
		case PRAlbumFileAttribute:
			return "ALBUM";
		case PRComposerFileAttribute:
			return "COMPOSER";
		case PRAlbumArtistFileAttribute:
			return "ALBUMARTIST";
		case PRBPMFileAttribute:
			return "BPM";
		case PRYearFileAttribute:
			return "DATE";
		case PRTrackNumberFileAttribute:
			return "TRACKNUMBER";
		case PRTrackCountFileAttribute:
			return "TOTALTRACKS";
		case PRDiscNumberFileAttribute:
			return "DISCNUMBER";
		case PRDiscCountFileAttribute:
			return "TOTALDISCS";
		case PRCommentsFileAttribute:
			return "DESCRIPTION";
		case PRGenreFileAttribute:
			return "GENRE";
        case PRCompilationFileAttribute:
            return "COMPILATION";
        case PRLyricsFileAttribute:
            return "LYRICS";
		default:
			return "";
			break;
	}
}

+ (NSString *)genreForID3Genre:(NSString *)genre
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PRID3Genres" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *string_ = [dictionary objectForKey:genre];
    
    if (string_) {
        return string_;
    }
    return genre;
}

+ (NSString *)ID3GenreForGenre:(NSString *)genre
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PRID3Genres" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *array = [dictionary allKeysForObject:genre];
    
    if ([array count] > 0) {
        return [array objectAtIndex:0];
    }
    return genre;
}

@end
