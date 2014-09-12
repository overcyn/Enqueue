#import <Foundation/Foundation.h>


@interface PRLibraryDescription : NSObject
- (id)initWithList:(PRList *)list connection:(PRConnection *)conn;
@property (nonatomic, readonly) NSInteger count;
- (PRItem *)itemForRow:(NSInteger)row;
- (NSInteger)rowForItem:(PRItem *)item;
- (id)valueForRow:(NSInteger)row attribute:(PRItemAttr *)attribute andCacheAttributes:(NSArray *(^)(void))attributes;

- (NSInteger)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr;
- (NSDictionary *)info;
- (NSArray *)albumCounts;

- (NSInteger)countForBrowser:(NSInteger)browser;
- (NSString *)valueForRow:(NSInteger)row browser:(NSInteger)browser;
- (NSIndexSet *)selectionForBrowser:(NSInteger)browser;
@end

@interface PRBrowserDescription : NSObject
- (id)initWithList:(PRList *)list browser:(NSInteger)browser connection:(PRConnection *)conn;
@end