#import <Foundation/Foundation.h>
#import "sqlite3.h"

void hfs_begins(sqlite3_context *ctx, int num_values, sqlite3_value **values);
int hfs_compare(void *udp, int lenA, const void *strA, int lenB, const void *strB);

BOOL no_case_begins(void *udp, int lenA, const void *strA, int lenB, const void *strB);
int no_case(void *udp, int lenA, const void *strA, int lenB, const void *strB);

CFRange PRFormatString(UniChar *string, int length);
