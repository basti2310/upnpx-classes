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

- (void)setRenderer: (MediaRenderer1Device *)rend
{
    MediaRenderer1Device* oldRender = renderer;
    
    //Remove the Old Observer, if any
    if(oldRender != nil)
    {
        if([[oldRender avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == YES)
            [[oldRender avTransportService] removeObserver:(BasicUPnPServiceObserver*)self];
    }

    renderer = rend;
    
    //Add New Observer, if any
    if(renderer != nil)
    {
        if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
            [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    }
}

#pragma mark - get URI

// return the right uri for a item
- (NSString *)getUriForItem: (MediaServer1ItemObject *)item
{
    NSString *uri;
    
    for (int i = 0; i < item.resources.count; i++)
    {
        MediaServer1ItemRes *itemRes = item.resources[i];
        NSRange range = [itemRes.protocolInfo rangeOfString:@"http-get:" options:NSCaseInsensitiveSearch];
        
        if(range.location == 0)
        {
            uri = [item.uriCollection objectForKey:itemRes.protocolInfo];
            break;
        }
        else
            uri = @"ERROR";
    }
    
    return uri;
}

#pragma mark - AVTransport Functions

- (int)play: (NSArray *)playlist position: (int)pos
{
    // Do we have a Renderer and a playlist?
    if(renderer == nil || playlist == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    // Is it a Media1ServerItem?
    if(![[playlist objectAtIndex:pos] isContainer])
    {
        // get uri
        NSString *uri = [self getUriForItem:(MediaServer1ItemObject *)[playlist objectAtIndex:pos]];
        
        // stop befor start playing a new item
        [[renderer avTransport] StopWithInstanceID:iid];
        
        // Play
        [[renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];                           // p. 32 - AVTransport:1 Service Template Version 1.01
        [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:@""];     // p. 18 - AVTransport:1 Service Template Version 1.01
        [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];                                             // p. 26 - AVTransport:1 Service Template Version 1.01
    }
    
    return 0;
}

- (int)replay
{
    // Do we have a Renderer?
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];         // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)stop
{
    // Do we have a Renderer?
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];

    [[renderer avTransport] StopWithInstanceID:iid];            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)pause
{
    // Do we have a Renderer?
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PauseWithInstanceID:iid];       // p. 27 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (NSDictionary *)getPositionAndTrackInfo
{
    // Do we have a Renderer?
    if(renderer == nil)
        return nil;
    
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
        item = [metaDataArray objectAtIndex:0];
    else
        item = nil;
    
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
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] SeekWithInstanceID:iid Unit:mode Target:target];        // p. 29 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)next
{
    // Do we have a Renderer?
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] NextWithInstanceID:iid];        // p. 30 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

- (int)previous
{
    // Do we have a Renderer?
    if(renderer == nil)
        return -1;
    
    //Lazy Observer attach
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    
    [[renderer avTransport] PreviousWithInstanceID:iid];        // p. 31 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

#pragma mark - Eventing

// https://code.google.com/p/upnpx/wiki/TutorialEventing
- (void)UPnPEvent: (BasicUPnPService *)sender events:(NSDictionary *)events
{
    NSLog(@"AVTransport Events: %@", events);
    
    if(sender == [renderer avTransportService])
    {
        NSString *newState = [events objectForKey:@"TransportStatus"];
        
        if([newState isEqualToString:@"ERROR_OCCURRED"])
        {
            NSLog(@"Can not play item!");
        }
    }
}

@end
