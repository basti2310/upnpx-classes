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
        NSParameterAssert(rend);
        NSParameterAssert(serv);
        
        server = serv;
        renderer = rend;
        
        // Lazy Observer attach
        // TODO: is it enough to register once in init and unregister once in dealloc? --> see REGISTERRRRRRRRRRRR log statements
        [self lazyObserverAttachAVTransportService];
        [self lazyObserverAttachRenderingControlService];
    }
    
    return self;
}

- (void)dealloc
{
    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == YES)
        [[renderer avTransportService] removeObserver:(BasicUPnPServiceObserver*)self];
    
    if([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver*)self] == YES)
        [[renderer renderingControlService] removeObserver:(BasicUPnPServiceObserver*)self];
}

+ (UPNPRendererType)deviceType: (BasicUPnPDevice *)device
{
    NSRange range = [device.manufacturer rangeOfString:@"sonos" options:NSCaseInsensitiveSearch];
    
    if(range.location != NSNotFound)
    {
        return UPNPRendererType_Sonos;
    }
    
    return UPNPRendererType_Generic;
}


#pragma mark -
#pragma mark - Content Directory

// get the folder/file hierarchy
- (NSArray *)browseContentForRootID: (NSString *)rootid
{
    //Allocate NMSutableString's to read the results
    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];
    
    // p. 22 - ContentDirectory:1 Service Template Version 1.01
    [[server contentDirectory] BrowseWithObjectID:rootid BrowseFlag:UPNP_DEFAULT_CONTENT_BROWSEFLAG Filter:UPNP_DEFAULT_BROWSE_FILTER StartingIndex:UPNP_DEFAULT_BROWSE_STARTINGINDEX RequestedCount:UPNP_DEFAULT_CONTENT_BROWSE_REQUESTEDCOUNT SortCriteria:UPNP_DEFAULT_BROWSE_SORTCRITERIA OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
        
    // The collections are returned as DIDL Xml in the string 'outResult'
    // upnpx provide a helper class to parse the DIDL Xml in usable MediaServer1BasicObject object
    // (MediaServer1ContainerObject and MediaServer1ItemObject)
    // Parse the return DIDL and store all entries as objects in the 'list' array
    NSMutableArray *list = [[NSMutableArray alloc] init];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:list itemsOnly:NO];
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
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
	
	[[server contentDirectory] BrowseWithObjectID:[object objectID] BrowseFlag:UPNP_DEFAULT_METADAT_BROWSEFLAG Filter:UPNP_DEFAULT_BROWSE_FILTER StartingIndex:UPNP_DEFAULT_BROWSE_STARTINGINDEX RequestedCount:UPNP_DEFAULT_METADATA_BROWSE_REQUESTEDCOUNT SortCriteria:UPNP_DEFAULT_BROWSE_SORTCRITERIA OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    
    return [metaData copy];
}


#pragma mark -
#pragma mark - AVTransport

// play an item
- (UPNP_Error)play: (MediaServer1BasicObject *)item
{
    if (renderer == nil || server == nil)   // no renderer or server
    {
        return UPNP_Error_NoRendererServer;
    }
    else if (item.isContainer)  // use other function -> - (int)playPlaylist: (MediaServer1ContainerObject *)object
    {
        return UPNP_Error_UseOtherFunction;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // get metaData
    NSString *metaData = [self browseMetaDataWithMediaObject:item];
    
    // get uri
    NSString *uri = [self getUriForItem:(MediaServer1ItemObject *)item];
    
    if (uri == nil)     // no uri for item
    {
        return UPNP_Error_NoUriForItem;
    }
    else if ([uri isEqualToString:@"error"])    // false protocol type for uri
    {
        return UPNP_Error_FalseProtocolType;
    }
    
    // stop befor start playing a new item
    // not every renderer needs this
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];                                                                            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID NewPlayMode:UPNP_DEFAULT_PLAY_MODE];                                               // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];        // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];                                                                 // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// play a container (folder/playlist)
- (UPNP_Error)playFolderPlaylist: (MediaServer1ContainerObject *)object
{
    if (renderer == nil || server == nil)     // no renderer or server
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // check uri
    NSString *uri = [self getUriForContainer:object];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return UPNP_Error_RendererError;
    }
    else if (uri == nil)    // no uri for folder
    {
        return UPNP_Error_NoUriForFolder;
    }
    
    // get meta data
    NSString *metaData = [self browseMetaDataWithMediaObject:object];
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // stop befor start playing a new item
    // not every renderer needs this
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];                                                        // p. 25 - AVTransport:1 Service Template Version 1.01
    
    // Play
    [[renderer avTransport] SetPlayModeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID NewPlayMode:UPNP_DEFAULT_PLAY_MODE];                           // p. 32 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:uri CurrentURIMetaData:[metaData XMLEscape]];     // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];                                             // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// if pause -> replay
- (UPNP_Error)replay
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];         // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// stop
- (UPNP_Error)stop
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] StopWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];            // p. 25 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// pause
- (UPNP_Error)pause
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PauseWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];       // p. 27 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// next (works only with playlist/folder)
- (UPNP_Error)next
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] NextWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];        // p. 30 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// previous (works only with playlist/folder)
- (UPNP_Error)previous
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] PreviousWithInstanceID:UPNP_DEFAULT_INSTANCE_ID];        // p. 31 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// seek
// mode: p. 10 & p. 15 - AVTransport:1 Service Template Version 1.01    example: @"REL_TIME"
// target: p. 16 - AVTransport:1 Service Template Version 1.01
- (UPNP_Error)seekWithMode: (NSString *)mode andTarget: (NSString *)target
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    [[renderer avTransport] SeekWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Unit:mode Target:target];        // p. 29 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
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
    
    // Lazy Observer attach
    [self lazyObserverAttachAVTransportService];
    
    // p. 22 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] GetPositionInfoWithInstanceID:UPNP_DEFAULT_INSTANCE_ID OutTrack:outTrack OutTrackDuration:outTrackDuration OutTrackMetaData:outTrackMetaData OutTrackURI:outTrackURI OutRelTime:outRelTime OutAbsTime:outAbsTime OutRelCount:outRelCount OutAbsCount:outAbsCount];
    
    NSMutableArray *metaDataArray = [NSMutableArray new];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:metaDataArray itemsOnly:NO];
    NSData *didl = [outTrackMetaData dataUsingEncoding:NSUTF8StringEncoding];
    [parser parseFromData:didl];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 outTrack,           UPNP_KEY_CURRENT_TRACK,
                                 outTrackDuration,   UPNP_KEY_TRACK_DURATION,
                                 outTrackMetaData,   UPNP_KEY_TRACK_METADATA,
                                 outTrackURI,        UPNP_KEY_TRACK_URI,
                                 outRelTime,         UPNP_KEY_REL_TIME,
                                 outAbsTime,         UPNP_KEY_ABS_TIME,
                                 outRelCount,        UPNP_KEY_REL_COUNT,
                                 outAbsCount,        UPNP_KEY_ABS_COUNT,
                                 nil];
    
    if (metaDataArray.count > 0)
    {
        info[UPNP_KEY_ITEM_OBJECT] = metaDataArray[0];
    }
    
    return [info copy];
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
    {
        NSLog(@"!!!! REGISTERRRRRRRRRRRR:lazyObserverAttachAVTransportService %@ !!!", self);
        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self];
    }
}

// converts a time string (01:45:33) into a float value
+ (int)timeStringIntoInt: (NSString *)timeString
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
+ (NSString *)intIntoTimeString: (int)value
{
    int hour, minutes, sec;
    NSString *hourStr, *minStr, *secStr;
    
    hour = value / 3600;
    minutes = (value % 3600) / 60;
    sec = (value % 3600) - (minutes * 60);

    hourStr = [NSString stringWithFormat:@"%02d", hour];
    minStr = [NSString stringWithFormat:@"%02d", minutes];
    secStr = [NSString stringWithFormat:@"%02d", sec];
    
    return [NSString stringWithFormat:@"%@:%@:%@", hourStr, minStr, secStr];
}



#pragma mark -
#pragma mark - Rendering

// set mute for channel
- (UPNP_Error)setMute: (BOOL)mute forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    NSString *muteStr;
    
    if (mute)
    {
        muteStr = @"1";
    }
    else
    {
        muteStr = @"0";
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetMuteWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredMute:muteStr];        // p. 34 - RenderingControl:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// get mute for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getMuteForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outMute = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetMuteWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentMute:outMute];     // p. 33 - RenderingControl:1 Service Template Version 1.01
    
    return [NSNumber numberWithInt:[outMute intValue]];
}

// set volume for channel
- (UPNP_Error)setVolume: (NSUInteger)vol forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetVolumeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredVolume:[NSString stringWithFormat:@"%d", (int)vol]];        // p. 35 - RenderingControl:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// get volume for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getVolumeForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outVolume = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetVolumeWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentVolume:outVolume];       // p. 35 - RenderingControl:1 Service Template Version 1.01
    
    return [NSNumber numberWithInt:[outVolume intValue]];
}

// set brightness
- (UPNP_Error)setBrightness: (NSUInteger)brigh
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetBrightnessWithInstanceID:UPNP_DEFAULT_INSTANCE_ID DesiredBrightness:[NSString stringWithFormat:@"%d", (int)brigh]];      // p. 22 - RenderingControl:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// get brightness
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getBrightness
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outBrightness = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetBrightnessWithInstanceID:UPNP_DEFAULT_INSTANCE_ID OutCurrentBrightness:outBrightness];       // p. 22 - RenderingControl:1 Service Template Version 1.01
    
    return [NSNumber numberWithInt:[outBrightness intValue]];
}

// set volume DB for channel
// TODO: check how many decimal places are needed
- (UPNP_Error)setVolumeDB: (float)volDB forChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] SetVolumeDBWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel DesiredVolume:[NSString stringWithFormat:@"%f", volDB]];        // p. 36 - RenderingControl:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}

// get volume DB for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getVolumeDBForChannel: (NSString *)channel
{
    if (renderer == nil)   // no renderer
    {
        return nil;
    }
    
    NSMutableString *outVolDB = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    [[renderer renderingControl] GetVolumeDBWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Channel:channel OutCurrentVolume:outVolDB];      // p. 36 - RenderingControl:1 Service Template Version 1.01
    
    return [NSNumber numberWithFloat:[outVolDB floatValue]];
}

// get volume DB range for channel
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeDBRangeForChannel: (NSString *)channel
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
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat:[outVolDBmin floatValue]], UPNP_KEY_VOLUME_DB_MIN,
            [NSNumber numberWithFloat:[outVolDBmax floatValue]], UPNP_KEY_VOLUME_DB_MAX,
            nil];
}

#pragma mark - helper functions

- (void)lazyObserverAttachRenderingControlService
{
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
    {
        NSLog(@"!!!! lazyObserverAttachRenderingControlService %@ !!!", self);
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    }
}



#pragma mark -
#pragma mark - Eventing

// https://code.google.com/p/upnpx/wiki/TutorialEventing
- (void)UPnPEvent:(BasicUPnPService *)sender events:(NSDictionary *)events
{
    NSLog(@"Events: %@", events);
    
    if (sender == [renderer avTransportService])
    {
        NSString *newState = [events objectForKey:UPNP_KEY_TRANSPORT_STATUS];
        
        if ([newState isEqualToString:UPNP_STATE_ERROR_OCCURRED])
        {
            // TODO: notify client code about error
            NSLog(@"Can not play item!");
        }
 
// does not work reliable:
//        newState = [events objectForKey:UPNP_KEY_TRANSPORT_STATE];
//        
//        if ([newState isEqualToString:UPNP_STATE_STOPPED])
//        {
//            NSLog(@"Track stopped!");
//        }
    }
    

// not used:
//    if (sender == [renderer renderingControlService])
//    {
//        NSString *state = [events objectForKey:@"Mute"];
//     
//        NSLog(@"Mute-State: %@", state);
//    }
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
    StateVariableRange *range = [serv.stateVariables objectForKey:UPNP_KEY_VOLUME];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min], UPNP_KEY_VOLUME_MIN,
            [NSNumber numberWithInt:range.max], UPNP_KEY_VOLUME_MAX,
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
    StateVariableList *list = [serv.stateVariables objectForKey:UPNP_KEY_A_ARG_TYPE_CHANNEL];
    
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
    StateVariableRange *range = [serv.stateVariables objectForKey:UPNP_KEY_VOLUME_DB];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min],           UPNP_KEY_VOLUME_DB_MIN,
            [NSNumber numberWithInt:range.max],           UPNP_KEY_VOLUME_DB_MAX,
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
