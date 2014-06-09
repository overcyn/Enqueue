#import <Foundation/Foundation.h>


@interface PRFileInfo : NSObject {
    NSMutableDictionary *_attributes;
    NSImage *_art;
    int _tempArt;
    PRItem *_item;
    int _trackid; // used by iTunesImport
}

@property (readwrite, retain) NSMutableDictionary *attributes;
@property (readwrite, retain) NSImage *art;
@property (readwrite) int tempArt;
@property (readwrite, retain) PRItem *item;
@property (readwrite) int trackid;

- (id)init;
+ (PRFileInfo *)fileInfo;

@end
