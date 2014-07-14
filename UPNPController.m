//
//  UPNPController.m
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 10.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "UPNPController.h"
#import "MediaServerBasicObjectParser.h"
#import "CocoaTools.h"
#import "StateVariable.h"
#import "StateVariableRange.h"
#import "StateVariableList.h"


#define ITEM_PROTOCOLS          @[@"http-get:"]
#define CONTAINER_PROTOCOLS     @[@"http-get:"]



@implementation UPNPController


#pragma mark - 
#pragma mark - Initialisation

- (instancetype)initWithRenderer: (MediaRenderer1Device *)rend andServer: (MediaServer1Device *)serv
{
    self = [super init];
    if (self)
    {
        self.currentBasicObject = nil;
        
        renderer = rend;
        server = serv;
        
        if (renderer != nil)
        {
            // Lazy Observer attach
            [self lazyObserverAttachAVTransportService];
            [self lazyObserverAttachRenderingControlService];
        }
    }
    
    return self;
}


#pragma mark -
#pragma mark - Content Directory

// get the folder/file hierarchy
- (NSArray *)browseContentForRootID: (NSString *)rootid
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    //Allocate NMSutableString's to read the results
    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];
    
    // p. 22 - ContentDirectory:1 Service Template Version 1.01
    [[server contentDirectory] BrowseWithObjectID:rootid BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    NSLog(@"// meta data: %@", outResult);
    
    // The collections are returned as DIDL Xml in the string 'outResult'
    // upnpx provide a helper class to parse the DIDL Xml in usable MediaServer1BasicObject object
    // (MediaServer1ContainerObject and MediaServer1ItemObject)
    // Parse the return DIDL and store all entries as objects in the 'list' array
    [list removeAllObjects];
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:list itemsOnly:NO];
    [parser parseFromData:didl];
    
    return [list copy];
}

// get the meta data for a MediaServer1BasicObject
- (NSString *)browseMetaDataWithMediaObject: (MediaServer1BasicObject *)object
{
	NSMutableString *metaData = [[NSMutableString alloc] init];
	NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
	NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
	NSMutableString *outUpdateID = [[NSMutableString alloc] init];
	
	[[server contentDirectory] BrowseWithObjectID:[object objectID] BrowseFlag:@"BrowseMetadata" Filter:@"*" StartingIndex:@"0" RequestedCount:@"1" SortCriteria:@"+dc:title" OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    return [metaData copy];
}


#pragma mark -
#pragma mark - AVTransport

// play an item
/*
error code:
1   no renderer or server
2   use other function -> - (int)playPlaylist: (MediaServer1ContainerObject *)object
3   no uri for item
4   false protocol type for uri
*/
- (int)play: (MediaServer1BasicObject *)item
{
    if (renderer == nil || server == nil)   // no renderer or server
    {
        return 1;
    }
    else if (item.isContainer)  // use other function -> - (int)playPlaylist: (MediaServer1ContainerObject *)object
    {
        return 2;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // get metaData
    NSString *metaData = [self browseMetaDataWithMediaObject:item];
    
    // get uri
    NSString *uri = [self getUriForItem:(MediaServer1ItemObject *)item];
    
    if (uri == nil)     // no uri for item
    {
        return 3;
    }
    else if ([uri isEqualToString:@"error"])    // false protocol type for uri
    {
        return 4;
    }
    
    // stop befor start playing a new item
    // not every renderer needs this
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];                                                                            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID NewPlayMode:@"NORMAL"];                                               // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];        // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:@"1"];                                                                 // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// play a container (folder/playlist)
/*
error code:
1   no renderer or server
2   render can not play object with this uri
3   no uri for folder
 */
- (int)playFolderPlaylist: (MediaServer1ContainerObject *)object
{
    if (renderer == nil || server == nil)     // no renderer or server
    {
        return 1;
    }
    
    // check uri
    NSString *uri = [self getUriForContainer:object];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return 2;
    }
    else if (uri == nil)    // no uri for folder
    {
        return 3;
    }
    
    // get meta data
    NSString *metaData = [self browseMetaDataWithMediaObject:object];
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // stop befor start playing a new item
    // not every renderer needs this
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];                                                        // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID NewPlayMode:@"NORMAL"];                           // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];     // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:@"1"];                                             // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// if pause -> replay
/*
 error code:
 1  no renderer
*/
- (int)replay
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:@"1"];         // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// stop
/*
 error code:
 1  no renderer
 */
- (int)stop
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// pause
/*
 error code:
 1  no renderer
 */
- (int)pause
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PauseWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];       // p. 27 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// next (works only with playlist/folder)
/*
 error code:
 1  no renderer
 */
- (int)next
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] NextWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];        // p. 30 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// previous (works only with playlist/folder)
/*
 error code:
 1  no renderer
 */
- (int)previous
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PreviousWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];        // p. 31 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// seek
// mode: p. 10 & p. 15 - AVTransport:1 Service Template Version 1.01    example: @"REL_TIME"
// target: p. 16 - AVTransport:1 Service Template Version 1.01
/*
 error code:
 1  no renderer
 */
- (int)seekWithMode: (NSString *)mode andTarget: (NSString *)target
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] SeekWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Unit:mode Target:target];        // p. 29 - AVTransport:1 Service Template Version 1.01
    
    return 0;
}

// get position and track info
/*
 error code:
 nil    no renderer
 */
/*
 dictionary keys:
 currentTrack
 trackDuration
 trackMetaData
 trackURI
 relTime
 absTime
 relCount
 absCount
 MediaServer1ItemObject
 */
- (NSDictionary *)getPositionAndTrackInfo
{
    if (renderer == nil)   // no renderer
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
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // p. 22 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] GetPositionInfoWithInstanceID:UPNP_DEFAULT_INSTANCE_ID OutTrack:outTrack OutTrackDuration:outTrackDuration OutTrackMetaData:outTrackMetaData OutTrackURI:outTrackURI OutRelTime:outRelTime OutAbsTime:outAbsTime OutRelCount:outRelCount OutAbsCount:outAbsCount];
    
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

#pragma mark - helper functions

// get the uri for an item
/*
 error code:
 nil    no uri for item
 error  false protocol type for uri
*/
- (NSString *)getUriForItem: (MediaServer1ItemObject *)item
{
    if (item.resources.count <= 0)  // no uri for item
    {
        return  nil;
    }
    
    for (MediaServer1ItemRes *itemRes in item.resources)
    {
        for (NSString *protocol in [self supportedItemProtocols])
        {
            NSRange protocolRange = [itemRes.protocolInfo rangeOfString:protocol options:NSCaseInsensitiveSearch];
            
            if (protocolRange.location != NSNotFound)
            {
                return [item.uriCollection objectForKey:itemRes.protocolInfo];
            }
        }
    }
    
    return @"error";    // false protocol type for uri
}

// get the uri for a container
/*
 error code:
 nil    no uri for item
 error  false protocol type for uri
 */
- (NSString *)getUriForContainer: (MediaServer1ContainerObject *)container
{
    if (container.uris.count <= 0)  // no uri for item
    {
        return nil;
    }
    
    for (NSString *uri in container.uris)
    {
        for (NSString *protocol in [self supportedContainerProtocols])
        {
            NSRange protocolRange = [uri rangeOfString:protocol options:NSCaseInsensitiveSearch];
            
            if (protocolRange.location != NSNotFound)
            {
                return uri;
            }
        }
    }
    
    return @"error";    // false protocol type for uri
}

- (NSArray *)supportedItemProtocols
{
    return ITEM_PROTOCOLS;
}

- (NSArray *)supportedContainerProtocols
{
    return CONTAINER_PROTOCOLS;
}

- (void)lazyObserverAttachAVTransportService
{
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO)
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
}

// converts a time string (01:45:33) into a float value
- (int)timeStringIntoInt: (NSString *)timeString
{
    NSScanner *timeScanner = [NSScanner scannerWithString:timeString];
    int hours, minutes, sec;
    
    [timeScanner scanInt:&hours];
    [timeScanner scanString:@":" intoString:nil];
    [timeScanner scanInt:&minutes];
    [timeScanner scanString:@":" intoString:nil];
    [timeScanner scanInt:&sec];
    
    return (hours * 3600 + minutes * 60 + sec);
}

// converts a float value into a time string (01:45:33)
- (NSString *)intIntoTimeString: (int)value
{
    int hour, minutes, sec;
    NSString *hourStr, *minStr, *secStr;
    
    hour = value / 3600;
    minutes = (value % 3600) / 60;
    sec = (value % 3600) - (minutes * 60);
    
    if (hour < 10)
        hourStr = [NSString stringWithFormat:@"0%d", hour];
    else
        hourStr = [NSString stringWithFormat:@"%d", hour];
    
    if (minutes < 10)
        minStr = [NSString stringWithFormat:@"0%d", minutes];
    else
        minStr = [NSString stringWithFormat:@"%d", minutes];
    
    if (sec < 10)
        secStr = [NSString stringWithFormat:@"0%d", sec];
    else
        secStr = [NSString stringWithFormat:@"%d", sec];
    
    return [NSString stringWithFormat:@"%@:%@:%@", hourStr, minStr, secStr];
}



#pragma mark -
#pragma mark - Rendering

// set mute for channel
/*
 error code:
 1  no renderer
 */
- (int)setMute: (NSString *)mut forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetMuteWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredMute:mut];        // p. 34 - RenderingControl:1 Service Template Version 1.01
    
    return 0;
}

// get mute for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getMuteForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outMute = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetMuteWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentMute:outMute];     // p. 33 - RenderingControl:1 Service Template Version 1.01
    
    return [outMute copy];
}

// set volume for channel
/*
 error code:
 1  no renderer
 */
- (int)setVolume: (NSString *)vol forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetVolumeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredVolume:vol];        // p. 35 - RenderingControl:1 Service Template Version 1.01
    
    return 0;
}

// get volume for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outVolume = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetVolumeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentVolume:outVolume];       // p. 35 - RenderingControl:1 Service Template Version 1.01
    
    return [outVolume copy];
}

// set brightness
/*
 error code:
 1  no renderer
 */
- (int)setBrightness: (NSString *)brigh
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetBrightnessWithInstanceID:UPNP_DEFAULT_INSTANCE_ID DesiredBrightness:brigh];      // p. 22 - RenderingControl:1 Service Template Version 1.01
    
    return 0;
}

// get brightness
/*
 error code:
 nil  no renderer
 */
- (NSString *)getBrightness
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outBrightness = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetBrightnessWithInstanceID:UPNP_DEFAULT_INSTANCE_ID OutCurrentBrightness:outBrightness];       // p. 22 - RenderingControl:1 Service Template Version 1.01
    
    return [outBrightness copy];
}

// set volume DB for channel
/*
 error code:
 1  no renderer
 */
- (int)setVolumeDB: (NSString *)volDB forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return 1;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetVolumeDBWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredVolume:volDB];        // p. 36 - RenderingControl:1 Service Template Version 1.01
    
    return 0;
}

// get volume DB for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeDBForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outVolDB = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetVolumeDBWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentVolume:outVolDB];      // p. 36 - RenderingControl:1 Service Template Version 1.01
    
    return [outVolDB copy];
}

// get volume DB range for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeDBRangeForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outVolDBmin = [[NSMutableString alloc] init];
    NSMutableString *outVolDBmax = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetVolumeDBRangeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutMinValue:outVolDBmin OutMaxValue:outVolDBmax];       // p. 37 - RenderingControl:1 Service Template Version 1.01
    
    return [NSString stringWithFormat:@"%@ - %@", outVolDBmin, outVolDBmax];
}

#pragma mark - helper functions

- (void)lazyObserverAttachRenderingControlService
{
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
}



#pragma mark -
#pragma mark - Eventing

// https://code.google.com/p/upnpx/wiki/TutorialEventing
- (void)UPnPEvent:(BasicUPnPService *)sender events:(NSDictionary *)events
{
    NSLog(@"Events: %@", events);
    
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
            NSLog(@"Track stopped!");
        }
    }
    
    if (sender == [renderer renderingControlService])
    {
        NSString *state = [events objectForKey:@"Mute"];
     
        NSLog(@"Mute-State: %@", state);
    }
}



#pragma mark -
#pragma mark - StateVariableRangeList

// get volume min & max
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeMinMax
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    BasicUPnPService *serv = [(BasicUPnPDevice *)renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableRange *range = [serv.stateVariables objectForKey:@"Volume"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min], @"VolumeMin",
            [NSNumber numberWithInt:range.max], @"VolumeMax",
            nil];
}

// get channel list
/*
 error code:
 nil  no renderer
 */
- (NSArray *)getChannelList
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    BasicUPnPService *serv = [(BasicUPnPDevice *)renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableList *list = [serv.stateVariables objectForKey:@"A_ARG_TYPE_Channel"];
    
    return list.list;
}

// get volume db min & max
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeDBMinMax
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    BasicUPnPService *serv = [(BasicUPnPDevice *)renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableRange *range = [serv.stateVariables objectForKey:@"VolumeDB"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min],           @"VolumeDBMin",
            [NSNumber numberWithInt:range.max],           @"VolumeDBMax",
            nil];
}



#pragma mark -
#pragma mark - ActionList

// get all available render actions for a urn
- (NSArray *)getAvailableRenderActionsForUrn: (NSString *)urn
{
    BasicUPnPDevice *device = (BasicUPnPDevice *)renderer;
    
    BasicUPnPService *serv = [device getServiceForType:urn];
    
    return [serv.actionList copy];
}

// get all available server actions for a urn
- (NSArray *)getAvailableServerActionsForUrn: (NSString *)urn
{
    BasicUPnPDevice *device = (BasicUPnPDevice *)server;
    
    BasicUPnPService *serv = [device getServiceForType:urn];
    
    return [serv.actionList copy];
}



@end
