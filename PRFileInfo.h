#import <Foundation/Foundation.h>


@interface PRFileInfo : NSObject {
    NSMutableDictionary *_attributes;
    NSImage *_art;
    int _tempArt;
    int _file;
    int _trackid; // used by iTunesImport
}

@property (readwrite, retain) NSMutableDictionary *attributes;
@property (readwrite, retain) NSImage *art;
@property (readwrite) int tempArt;
@property (readwrite) int file;
@property (readwrite) int trackid;

- (id)init;
+ (PRFileInfo *)fileInfo;

@end
