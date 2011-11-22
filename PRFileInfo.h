#import <Foundation/Foundation.h>

@interface PRFileInfo : NSObject 
{
    NSMutableDictionary *_attributes;
    NSImage *_art;
    int _tempArt;
    int _file;
}

@property (readwrite, retain) NSMutableDictionary *attributes;
@property (readwrite, retain) NSImage *art;
@property (readwrite) int tempArt;
@property (readwrite) int file;

- (id)init;
+ (PRFileInfo *)fileInfo;

@end
