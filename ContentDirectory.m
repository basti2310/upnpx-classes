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

@implementation ContentDirectory

- (instancetype)init
{
    self = [super init];
    if (self)
    {

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

- (NSArray *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem andDevice: (MediaServer1Device *)device
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

    return [metaDataRadio copy];
}

@end
