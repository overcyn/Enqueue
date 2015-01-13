#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@interface PRFileInfo : NSObject {
    NSMutableDictionary *_attributes;
    NSImage *_art;
    int _tempArt;
    PRItemID *_item;
    int _trackid; // used by iTunesImport
}

@property (readwrite, strong) NSMutableDictionary *attributes;
@property (readwrite, strong) NSImage *art;
@property (readwrite) int tempArt;
@property (readwrite, strong) PRItemID *item;
@property (readwrite) int trackid;

- (id)init;
+ (PRFileInfo *)fileInfo;

@end
