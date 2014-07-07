//
//  AVTransport.m
//  
//
//  Created by Sebastian Peischl on 07.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "AVTransport.h"
#import "BasicUPnPService.h"
#import "MediaServerBasicObjectParser.h"
#import "otherFunctions.h"
#import "ContentDirectory.h"
#import "CocoaTools.h"

static AVTransport *avTransport = nil;
static NSString *iid = @"0";                // p. 16 - AVTransport:1 Service Template Version 1.01
                                            // p. 6/1.2 - RenderingControl:1 Service Template Version 1.01
                                            // p. 17 - RenderingControl:1 Service Template Version 1.01
                                            // p. 39/2.5.1 - RenderingControl:1 Service Template Version 1.01

@interface AVTransport ()


@end

@implementation AVTransport
{
    MediaRenderer1Device *renderer;
    MediaServer1Device *server;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        renderer = nil;
    }

    return self;
}

+ (AVTransport *)getInstance
{
    if (avTransport == nil)
        avTransport = [[AVTransport alloc] init];
    
    return avTransport;
}

- (void)setRenderer: (MediaRenderer1Device *)rend andServer: (MediaServer1Device *)serv
{
    MediaRenderer1Device* oldRender = renderer;
    server = serv;
    
    //Remove the Old Observer, if any
    if (oldRender != nil)
    {
        if([[oldRender avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == YES)
            [[oldRender avTransportService] removeObserver:(BasicUPnPServiceObserver*)self];
    }

    renderer = rend;
    
    //Add New Observer, if any
    if (renderer != nil)
    {
        if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
            [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    }
}

#pragma mark - get URI

- (NSString *)getUriForItem: (MediaServer1ItemObject *)item
{
    NSString *uri;
        
    for (int i = 0; i < item.resources.count; i++)
    {
        MediaServer1ItemRes *itemRes = item.resources[i];
        NSLog(@"// item res: %@", item.protocolInfo);

        NSRange range1 = [itemRes.protocolInfo rangeOfString:@"http-get:" options:NSCaseInsensitiveSearch];
        NSRange range2 = [itemRes.protocolInfo rangeOfString:@"x-file-cifs:" options:NSCaseInsensitiveSearch];
        NSRange range3 = [itemRes.protocolInfo rangeOfString:@"x-sonosapi-stream:" options:NSCaseInsensitiveSearch];
        
        if((range1.location == 0) || (range2.location == 0) || (range3.location == 0))
        {
            uri = [item.uriCollection objectForKey:itemRes.protocolInfo];
            break;
        }
        else
            uri = nil;
    }
    
    return uri;
}

- (NSString *)getUriForContainer: (MediaServer1ContainerObject *)container
{
    if (container.uris.count == 0)
    {
        return nil;
    }
    
    for (NSString *uri in container.uris)
    {
        NSRange range1 = [uri rangeOfString:@"http-get:" options:NSCaseInsensitiveSearch];
        NSRange range2 = [uri rangeOfString:@"x-file-cifs:" options:NSCaseInsensitiveSearch];
        NSRange range3 = [uri rangeOfString:@"x-rincon-playlist:" options:NSCaseInsensitiveSearch];
        
        if((range1.location == 0) || (range2.location == 0) || (range3.location == 0))
        {
            return uri;
        }
    }
    
    return @"error";
}

#pragma mark - AVTransport Functions

- (int)play: (MediaServer1BasicObject *)item
{
    // Do we have a Renderer and a server?
    if (renderer == nil || server == nil)
    {
        return -1;
    }
    
    if (item.isContainer)  // use other function -> - (int)playPlaylist: (MediaServer1ContainerObject *)object
    {
        return 1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    // get metaData
    NSString *metaData = [[ContentDirectory getInstance] browseMetaDataWithMediaItem:(MediaServer1ItemObject *)item andDevice:server];
    
    NSLog(@"// meta data item: %@", metaData);
    
    // get uri
    NSString *uri = [self getUriForItem:(MediaServer1ItemObject *)item];
    
    // stop befor start playing a new item
    [[renderer avTransport] StopWithInstanceID:iid];                                                                            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];                                               // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];        // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];                                                                 // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)playPlaylist: (MediaServer1ContainerObject *)object
{
    // Do we have a Renderer and a playlist?
    if (renderer == nil || server == nil)
    {
        return -1;
    }
    
    // check uri
    NSString *uri = [self getUriForContainer:object];
    
    // get meta data
    NSString *metaData = [[ContentDirectory getInstance] browseMetaDataWithMediaContainer:object andDevice:server];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return 1;
    }
    else if (uri == nil)    // no uri for folder
    {
        return 2;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    // stop befor start playing a new item
    [[renderer avTransport] StopWithInstanceID:iid];                                                        // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];                           // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];     // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];                                             // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)playRadio: (MediaServer1ItemObject *)item
{
    // Do we have a Renderer and a server?
    if (renderer == nil || server == nil)
    {
        return -1;
    }
    
    // check uri
    NSString *uri = [self getUriForItem:item];
    
    NSLog(@"// radio uri: %@", uri);
    
    // get meta data
    NSString *metaData = [[ContentDirectory getInstance] browseMetaDataWithMediaItem:item andDevice:server];
    
    NSLog(@"// meta data radio: %@", metaData);
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return 1;
    }
    else if (uri == nil)    // no uri for folder
    {
        return 2;
    }

    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    
    // Play
    [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];        // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];                                                                 // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)replay
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];         // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)stop
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];

    [[renderer avTransport] StopWithInstanceID:iid];            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)pause
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PauseWithInstanceID:iid];       // p. 27 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (NSDictionary *)getPositionAndTrackInfo
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return nil;
    }
    
    NSMutableString *outTrack = [[NSMutableString alloc] init];
    NSMutableString *outTrackDuration = [[NSMutableString alloc] init];
    NSMutableString *outTrackMetaData = [[NSMutableString alloc] init];
    NSMutableString *outTrackURI = [[NSMutableString alloc] init];
    NSMutableString *outRelTime = [[NSMutableString alloc] init];
    NSMutableString *outAbsTime = [[NSMutableString alloc] init];
    NSMutableString *outRelCount = [[NSMutableString alloc] init];
    NSMutableString *outAbsCount = [[NSMutableString alloc] init];
    
    NSMutableArray *metaDataArray = [NSMutableArray new];
    
    MediaServer1ItemObject *item = nil;
        
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    // p. 22 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] GetPositionInfoWithInstanceID:iid OutTrack:outTrack OutTrackDuration:outTrackDuration OutTrackMetaData:outTrackMetaData OutTrackURI:outTrackURI OutRelTime:outRelTime OutAbsTime:outAbsTime OutRelCount:outRelCount OutAbsCount:outAbsCount];
    
    [metaDataArray removeAllObjects];
    NSData *didl = [outTrackMetaData dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:metaDataArray itemsOnly:NO];
    [parser parseFromData:didl];
    
    if (metaDataArray.count > 0)
    {
        item = [metaDataArray objectAtIndex:0];
    }
    else
    {
        item = nil;
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    outTrack,           @"currentTrack",
                                    outTrackDuration,   @"trackDuration",
                                    outTrackMetaData,   @"trackMetaData",
                                    outTrackURI,        @"trackURI",
                                    outRelTime,         @"relTime",
                                    outAbsTime,         @"absTime",
                                    outRelCount,        @"relCount",
                                    outAbsCount,        @"absCount",
                                    item,               @"MediaServer1ItemObject",
                                    nil];
}

- (int)seekWithMode: (NSString *)mode andTarget: (NSString *)target
{
    // mode: p. 10 & p. 15 - AVTransport:1 Service Template Version 1.01    example: @"REL_TIME"
    // target: p. 16 - AVTransport:1 Service Template Version 1.01 

    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] SeekWithInstanceID:iid Unit:mode Target:target];        // p. 29 - AVTransport:1 Service Template Version 1.01
        
    return 0;
}

- (int)next
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] NextWithInstanceID:iid];        // p. 30 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)previous
{
    // Do we have a Renderer?
    if (renderer == nil)
    {
        return -1;
    }
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PreviousWithInstanceID:iid];        // p. 31 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

#pragma mark - Eventing

// https://code.google.com/p/upnpx/wiki/TutorialEventing
- (void)UPnPEvent:(BasicUPnPService *)sender events:(NSDictionary *)events
{
    NSLog(@"AVTransport Events: %@", events);
    
    if (sender == [renderer avTransportService])
    {
        NSString *newState = [events objectForKey:@"TransportStatus"];
        
        if ([newState isEqualToString:@"ERROR_OCCURRED"])
        {
            NSLog(@"Can not play item!");
        }
        
        newState = [events objectForKey:@"TransportState"];
        
        if ([newState isEqualToString:@"STOPPED"])
        {
        }
    }
}

@end
