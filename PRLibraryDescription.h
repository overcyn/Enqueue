#import <Foundation/Foundation.h>

@interface PRLibraryDescription : NSObject
- (id)initWithList:(PRList *)list connection:(PRConnection *)conn;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSArray *info;
@property (nonatomic, readonly) NSArray *albumCounts;
- (PRItem *)itemForRow:(NSInteger)row;
- (NSInteger)rowForItem:(PRItem *)item;
- (id)valueForRow:(NSInteger)row attribute:(PRItemAttr *)attribute andCacheAttributes:(NSArray *(^)(void))attributes;
- (NSInteger)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr;
@end

@interface PRBrowserDescription : NSObject
- (id)initWithList:(PRList *)list browser:(NSInteger)browser connection:(PRConnection *)conn;
@property (nonatomic, readonly) PRItemAttr *attribute;
@property (nonatomic, readonly) NSInteger count; // Doesn't include 'All'
@property (nonatomic, readonly) NSIndexSet *selection;
@property (nonatomic, readonly) BOOL hasCompilation;
@property (nonatomic, readonly) NSString *title;
- (NSString *)valueForRow:(NSInteger)row;
@end