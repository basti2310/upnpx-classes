//
//  ContentDirectory.m
//  
//
//  Created by Sebastian Peischl on 11.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "ContentDirectory.h"
#import "MediaServerBasicObjectParser.h"

static ContentDirectory *contentDir = nil;

@interface ContentDirectory ()

@property (nonatomic, strong) NSMutableArray *queueDic;


@end

@implementation ContentDirectory

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.queueDic = [NSMutableArray new];
    }
    
    return self;
}

+ (ContentDirectory *)getInstance
{
    if (contentDir == nil)
        contentDir = [[ContentDirectory alloc] init];
    
    return contentDir;
}

#pragma mark - Browse

- (NSArray *)browseContentWithDevice: (MediaServer1Device *)device andRootID: (NSString *)rootid
{
    NSMutableArray *playlist = [[NSMutableArray alloc] init];
    
    //Allocate NMSutableString's to read the results
    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];
    
    // p. 22 - ContentDirectory:1 Service Template Version 1.01
    [[device contentDirectory] BrowseWithObjectID:rootid BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    //NSLog(@"// meta data: %@", outResult);
        
    // The collections are returned as DIDL Xml in the string 'outResult'
    // upnpx provide a helper class to parse the DIDL Xml in usable MediaServer1BasicObject object
    // (MediaServer1ContainerObject and MediaServer1ItemObject)
    // Parse the return DIDL and store all entries as objects in the 'mediaObjects' array
    [playlist removeAllObjects];
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:playlist itemsOnly:NO];
    [parser parseFromData:didl];
    
    return [playlist copy];
}

- (NSString *)browseMetaDataWithMediaItem: (MediaServer1ItemObject *)mediaItem andDevice: (MediaServer1Device *)device
{
	NSMutableString *metaData = [[NSMutableString alloc] init];
	NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
	NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
	NSMutableString *outUpdateID = [[NSMutableString alloc] init];
	
	[[device contentDirectory] BrowseWithObjectID:[mediaItem objectID] BrowseFlag:@"BrowseMetadata" Filter:@"*" StartingIndex:@"0" RequestedCount:@"1" SortCriteria:@"+dc:title" OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    return [metaData copy];
}

- (NSString *)browseMetaDataWithMediaContainer: (MediaServer1ContainerObject *)mediaContainer andDevice: (MediaServer1Device *)device
{
	NSMutableString *metaData = [[NSMutableString alloc] init];
	NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
	NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
	NSMutableString *outUpdateID = [[NSMutableString alloc] init];
	
	[[device contentDirectory] BrowseWithObjectID:[mediaContainer objectID] BrowseFlag:@"BrowseMetadata" Filter:@"*" StartingIndex:@"0" RequestedCount:@"1" SortCriteria:@"+dc:title" OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    return [metaData copy];
}




// only for sonos
- (NSString *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem andDevice: (MediaServer1Device *)device
{
    NSMutableArray *metaDataRadio = [[NSMutableArray alloc] init];
    
	NSMutableString *metaData = [[NSMutableString alloc] init];
	NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
	NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
	NSMutableString *outUpdateID = [[NSMutableString alloc] init];
	
	[[device contentDirectory] BrowseWithObjectID:[mediaItem objectID] BrowseFlag:@"BrowseMetadata" Filter:@"*" StartingIndex:@"0" RequestedCount:@"1" SortCriteria:@"+dc:title" OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    [metaDataRadio removeAllObjects];
    NSData *didl = [metaData dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:metaDataRadio itemsOnly:YES];
    [parser parseFromData:didl];
    
    if (metaDataRadio.count > 0)
    {
        return [(MediaServer1ItemObject *)metaDataRadio[0] resMD];
    }

    return nil;
}

- (NSArray *)getQueuesOfMediaDirectoryOnServer: (MediaServer1Device *)server withRootID: (NSString *)rootid
{
    NSMutableArray *queueContainer = [NSMutableArray new];
    NSArray *mediaObjects = [self browseContentWithDevice:server andRootID:rootid];
    
    for (MediaServer1BasicObject *object in mediaObjects)
    {
        if (object.isContainer)
        {
            MediaServer1ContainerObject *container = (MediaServer1ContainerObject *)object;
            NSRange rangeName = [container.title rangeOfString:@"queue" options:NSCaseInsensitiveSearch];
            NSRange rangeUri;
            
            if (container.uris.count > 0)
            {
                rangeUri = [container.uris[0] rangeOfString:@"x-rincon-queue:" options:NSCaseInsensitiveSearch];
            }
            
            if (rangeName.location != NSNotFound)
            {
                [queueContainer addObject:container];
                
                if (container.uris.count > 0)
                {
                    if (rangeUri.location != NSNotFound)
                    {
                        [self.queueDic addObject:container.uris[0]];
                    }
                }
            }
            else if (container.uris.count > 0)
            {
                if (rangeUri.location != NSNotFound)
                {
                    [self.queueDic addObject:container.uris[0]];
                }
            }
        }
    }
    
    if (self.queueDic.count <= 0)
    {
        for (MediaServer1ContainerObject *container in queueContainer)
        {
            [self getQueuesOfMediaDirectoryOnServer:server withRootID:container.objectID];
        }
    }
    
    return [self.queueDic copy];
}

@end
