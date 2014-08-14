#import <Foundation/Foundation.h>

@class PRDb;


@interface PRListDescription : NSObject
+ (PRListDescription *)listDescriptionForList:(PRList *)list database:(PRDb *)db;
- (PRList *)list;
- (NSInteger)count;
- (PRItem *)itemAtIndex:(NSInteger)index;
@end
