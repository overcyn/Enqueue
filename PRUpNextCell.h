#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, PRUpNextCellIconType) {
    PRUpNextCellIconTypeNone,
    PRUpNextCellIconTypePlaying,
    PRUpNextCellIconTypeMissing,
};

@interface PRUpNextCell : NSCell 
@end

@interface PRUpNextCellModel : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *badge;
@property (nonatomic) PRUpNextCellIconType iconType;
@end
