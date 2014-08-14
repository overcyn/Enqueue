#import "PRListDescription.h"


@implementation PRListDescription {
    PRList *_list;
    NSArray *_items;
}

+ (PRListDescription *)listDescriptionForList:(PRList *)list database:(PRDb *)db {
    return nil;
}

- (PRList *)list {
    return _list;
}

- (NSInteger)count {
    return [_items count];
}

- (PRItem *)itemAtIndex:(NSInteger)index {
    return [_items objectAtIndex:index];
}

@end
