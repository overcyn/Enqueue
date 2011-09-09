#import "PRAlbumArtOperation.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonDigest.h>
#import "hmac_sha2.h"

NSString * const PRAmazonAssociatesTag = @"listen00-20";
NSString * const PRAWSAccessKeyID = @"AKIAJEKSV7F2JNSLPULA";
NSString * const PRAWSSecretAccessKey = @"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";


@implementation PRAlbumArtOperation

- (id)initWithDb:(PRDb *)db_
{
    self = [super init];
	if (self) {
		db = db_;
		library = [db library];
		prevArtist = @"";
		prevAlbum = @"";
        prevAlbumArt = nil;
	}
	
	return self;
}

- (void)main
{
	NSArray *fileIDArray;
//    PRAlbumArtController *albumArtController = [db albumArtController];
//	[library arrayOfFileIDsSortedByAlbumAndArtist:&fileIDArray _error:nil];
	
	for (NSNumber *i in fileIDArray) {
        NSLog(@"%@",i);
        NSImage *albumArt = [self albumArtForFile:[i intValue]];
        if (albumArt) {
            NSLog(@"found");
//            [albumArtController setDownloadedAlbumArt:albumArt forFile:[i intValue] _error:nil];
        }
	}
}

- (NSImage *)albumArtForFile:(PRFile)file
{
	NSString *artist = [library valueForFile:file attribute:PRArtistFileAttribute];
	NSString *album = [library valueForFile:file attribute:PRAlbumFileAttribute];
	
	if ([artist isEqualToString:@""] || [album isEqualToString:@""]) {
        return nil;
	}
	if ([artist isEqualToString:prevArtist] && [album isEqualToString:prevAlbum]) {
		return prevAlbumArt;
	}
	
    NSImage *albumArt = [[self class] amazonAlbumArtForArtist:artist album:album];
    prevArtist = artist;
	prevAlbum = album;
    prevAlbumArt = albumArt;
    
    return albumArt;
}

+ (NSImage *)amazon2AlbumArtForArtist:(NSString *)artist album:(NSString *)album
{
    NSMutableString *URLString = 
      [NSMutableString stringWithString:@"http://www.amazon.com/gp/search/ref=sr_adv_m_pop/"];
    [URLString appendFormat:@"?search-alias=%@", @"popular"];
    [URLString appendFormat:@"&field-artist=%@", artist];
    [URLString appendFormat:@"&field-title=%@", album];
    [URLString appendFormat:@"&sort=%@", @"relevancerank"];
    NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:URL 
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:10];
    NSURLResponse *URLResponse;
    NSError *e;
    NSData *URLData = 
      [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&URLResponse error:&e];
    if (!URLData) {
        return nil;
    }
    
//    NSString *string_ = [[NSString alloc] initWithData:URLData encoding:NSASCIIStringEncoding];
    return nil;
}

+ (NSImage *)amazonAlbumArtForArtist:(NSString *)artist album:(NSString *)album
{
    NSString *keywords = [NSString stringWithFormat:@"%@ %@", artist, album];
    NSCalendarDate *date = 
      [[NSCalendarDate calendarDate] addTimeInterval:(0 - [[NSTimeZone localTimeZone] secondsFromGMT])];
    NSString *timestamp = [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ"
                                                     timeZone:nil
                                                       locale:nil];
    NSMutableString *URLString = 
      [NSMutableString stringWithString:@"ecs.amazonaws.com/onca/xml?"];
    [URLString appendFormat:@"Service=%@", @"AWSECommerceService"];
    [URLString appendFormat:@"&AssociateTag=%@", PRAmazonAssociatesTag];
    [URLString appendFormat:@"&AWSAccessKeyId=%@", PRAWSAccessKeyID];
    [URLString appendFormat:@"&Operation=%@", @"ItemSearch"];
    [URLString appendFormat:@"&Version=%@", @"2005-10-05"]; // Version of the Product Advertising API 4.0 WSDL
    [URLString appendFormat:@"&SearchIndex=%@", @"MP3Downloads"];
    [URLString appendFormat:@"&Keywords=%@", keywords];
    [URLString appendFormat:@"&ResponseGroup=%@", @"Images"];
    [URLString appendFormat:@"&Timestamp=%@", timestamp];
    NSURL *URL = 
      [NSURL URLWithString:[[self class] amazonSignedURL:[NSString stringWithString:URLString]]];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:URL
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                            timeoutInterval:10];
	
	// send request
	NSURLResponse *response;
	NSError *e;
	NSData *URLData = 
      [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&e];
	if (!URLData) {
        return nil;
    }
    
    // parse data
    NSXMLDocument *XMLDocument = 
      [[[NSXMLDocument alloc] initWithData:URLData options:NSXMLDocumentTidyXML error:nil] autorelease];
    NSLog(@"%@",XMLDocument);
    NSXMLNode *rootNode = [XMLDocument rootElement];
    NSArray *array = [rootNode nodesForXPath:@"Items/Item/LargeImage/URL" error:nil];
    if ([array count] == 0) {
        return nil;
    }
        
    // create and send second URL request
	URL = [NSURL URLWithString:[[array objectAtIndex:0] stringValue]];
	URLRequest = [NSURLRequest requestWithURL:URL 
								  cachePolicy:NSURLRequestReturnCacheDataElseLoad 
							  timeoutInterval:10];
	URLData = [NSURLConnection sendSynchronousRequest:URLRequest 
									returningResponse:&response 
												error:&e];
	if (!URLData) {
        return nil;
    }
	
	// create image
	NSImage *albumArt = [[[NSImage alloc] initWithData:URLData] autorelease];
    if (![albumArt isValid]) {
        return nil;
    }
    
    return albumArt;
}

+ (NSString *)amazonSignedURL:(NSString *)URLString
{
    URLString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                    (CFStringRef)URLString, 
                                                                    NULL,
                                                                    (CFStringRef)@"\"',+:",
                                                                    kCFStringEncodingUTF8);
    NSArray *components = [URLString componentsSeparatedByString:@"?"];
    [URLString release];
    NSMutableArray *parameters = 
      [NSMutableArray arrayWithArray:[[components objectAtIndex:1] componentsSeparatedByString:@"&"]];
    [parameters sortUsingSelector:@selector(compare:)];
    NSString *cannonicalString =
        [NSString stringWithFormat:@"GET\necs.amazonaws.com\n/onca/xml\n%@",[parameters componentsJoinedByString:@"&"]];
    
    unsigned char hmac_buffer[SHA256_DIGEST_SIZE];
    bzero(hmac_buffer, SHA256_DIGEST_SIZE);
    unsigned char *strBytes = (unsigned char *)[cannonicalString UTF8String];
    unsigned char *keyBytes = (unsigned char *)[PRAWSSecretAccessKey UTF8String];
    hmac_sha256(keyBytes, [PRAWSSecretAccessKey length], strBytes, [cannonicalString length], hmac_buffer, SHA256_DIGEST_SIZE);
    
    NSData *signedData = [NSData dataWithBytes:hmac_buffer length:CC_SHA256_DIGEST_LENGTH];
    NSString *base = [signedData base64EncodingWithLineLength:0];
    base = [base stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    base = [base stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    base = [base stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    
    [parameters addObject:[NSString stringWithFormat:@"Signature=%@",base]];
    [parameters sortUsingSelector:@selector(compare:)];
    return [NSString stringWithFormat:@"http://%@?%@", [components objectAtIndex:0], [parameters componentsJoinedByString:@"&"]];
}

+ (NSImage *)freecoversAlbumArtForArtist:(NSString *)artist album:(NSString *)album
{
    // create URL request
    NSString *URLString = 
      [NSString stringWithFormat:@"http://www.freecovers.net/api/search/%@ %@", artist, album];
    URLString = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:URL
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                            timeoutInterval:10];
    
    // send request
	NSURLResponse *response;
	NSError *e;
	NSData *URLData = 
        [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&e];
    
    if (!URLData) {
        return nil;
    }
    
//    NSXMLDocument *XML = 
//        [[NSXMLDocument alloc] initWithData:URLData options:NSXMLDocumentTidyXML error:nil];
    
    return nil;
}

+ (NSImage *)lastfmAlbumArtForArtist:(NSString *)artist album:(NSString *)album
{
    // create URL request
	NSString *URLString = 
        [NSString stringWithFormat:
         @"http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=%@&artist=%@&album=%@",
         @"9e6a08d552a2e037f1ad598d5eca3802",
         artist,
         album];
	URLString = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *URL = [NSURL URLWithString:URLString];
	NSURLRequest *URLRequest = [NSURLRequest requestWithURL:URL
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                            timeoutInterval:10];
	
	// send request
	NSURLResponse *response;
	NSError *e;
	NSData *urlData = 
        [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&e];
	if (!urlData) {
		return nil;
	}
	
	// parse results
	NSString *responseString = [[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] autorelease];
	NSArray *resultsArray = 
        [responseString componentsSeparatedByString:@"<image size=\"extralarge\">"];
    
	if ([resultsArray count] == 1) {
        return nil;
	}
    responseString = [resultsArray objectAtIndex:1];
    resultsArray = [responseString componentsSeparatedByString:@"</image>"];
    responseString = [resultsArray objectAtIndex:0];    
	
	// create second URL request
	URL = [NSURL URLWithString:responseString];
	URLRequest = [NSURLRequest requestWithURL:URL 
								  cachePolicy:NSURLRequestReturnCacheDataElseLoad 
							  timeoutInterval:10];
	
	// send request
	urlData = [NSURLConnection sendSynchronousRequest:URLRequest 
									returningResponse:&response 
												error:&e];
	if (!urlData) {
		return nil;
	}
	
	// save data
	NSImage *albumArt = [[[NSImage alloc] initWithData:urlData] autorelease];
    if (![albumArt isValid]) {
        return nil;
    } 
    
    return albumArt;
}

@end