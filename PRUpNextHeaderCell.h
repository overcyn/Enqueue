#import <Cocoa/Cocoa.h>

@interface PRUpNextHeaderCell : NSActionCell
@end

@interface PRUpNextHeaderCellModel : NSObject
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic) BOOL compilation;
@end
