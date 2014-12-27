#import <Foundation/Foundation.h>
#import "PRLibraryViewController.h"

@interface PRListDescription : NSObject
- (id)initWithList:(PRList *)list connection:(PRConnection *)conn;
- (BOOL)writeToConnection:(PRConnection *)conn;
@property (nonatomic, readonly) PRList *list;
- (void)setValue:(id)value forAttr:(PRListAttr *)attr;
- (id)valueForAttr:(PRListAttr *)attr;

@property (nonatomic) PRBrowserPosition vertical;
@property (nonatomic) CGFloat verticalBrowserWidth;
@property (nonatomic) CGFloat horizontalBrowserHeight;
@property (nonatomic) BOOL listViewAscending;
@property (nonatomic) BOOL albumListViewAscending;
@property (nonatomic, strong) PRItemAttr *listViewSortAttr;
@property (nonatomic, strong) PRItemAttr *albumListViewSortAttr;
@property (nonatomic, strong) NSArray *browserSelections; // Array of three arrays of NSString
@property (nonatomic, strong) NSArray *browserAttributes; // Can be NSNull
@property (nonatomic, strong) NSArray *listViewInfo;
@property (nonatomic, strong) NSArray *albumListViewInfo;
@property (nonatomic, strong) PRListType *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *search;
@property (nonatomic) PRLibraryViewMode viewMode;
@property (nonatomic) NSDictionary *rules;
@end

@interface PRListDescription ()
@property (nonatomic, readonly) NSArray *derivedBrowserAttributes; // Can be NSNull
@property (nonatomic, readonly) NSArray *derivedBrowserAllowsCompilation;
@end
