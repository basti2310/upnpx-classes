//
//  SonosUPNPController.m
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 11.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "SonosUPNPController.h"
#import "CocoaTools.h"
#import "MediaServerBasicObjectParser.h"


#define SONOS_ITEM_PROTOCOLS            @[@"x-file-cifs:", @"x-sonosapi-radio:", @"x-sonosapi-stream:"]
#define SONOS_CONTAINER_PROTOCOLS       @[@"x-file-cifs:", @"x-rincon-playlist:", @"file:"]
#define SONOS_RADIO_PROTOCOLS           @[@"x-sonosapi-radio:", @"x-sonosapi-stream:"]


// TODO: find albumArt url

@implementation SonosUPNPController
{
    NSMutableArray *queueUris;
}


- (instancetype)initWithRenderer:(MediaRenderer1Device *)rend andServer:(MediaServer1Device *)serv
{
    self = [super initWithRenderer:rend andServer:serv];
    if (self)
    {
        queueUris = [NSMutableArray new];
        
        [self getQueueOfMediaDirectoryOnServerWithRootID:UPNP_DEFAULT_ROOT_ID];
    }
    return self;
}


#pragma mark -
#pragma mark - AVTransport

// play radio
- (UPNP_Error)playRadio: (MediaServer1ItemObject *)item
{
    if (renderer == nil || server == nil)
    {
        return UPNP_Error_NoRendererServer;
    }
    
    // check uri
    NSString *uri = [self getUriForItem:item];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return UPNP_Error_RendererError;
    }
    else if (uri == nil)    // no uri for item
    {
        return UPNP_Error_NoUriForItem;
    }
    
    // get meta data
    NSString *metaData = [self browseMetaDataForRadioWithMediaItem:item];
    
    if (metaData == nil)    // not meta data for radio
    {
        return UPNP_Error_Sonos_NoMetaData;
    }
    
    //Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    // Play
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:[uri XMLEscape] CurrentURIMetaData:[metaData XMLEscape]];        // p. 18 - AVTransport:1 Service Template Version 1.01
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];                                                                 // p. 26 - AVTransport:1 Service Template Version 1.01
    
    return UPNP_Error_OK;
}


// add item to queue and play the item
- (UPNP_Error)playItemWithQueue: (MediaServer1BasicObject *)item
{
    if (renderer == nil || server == nil)
    {
        return UPNP_Error_NoRendererServer;
    }
    
    //Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    // get metaData
    NSString *metaData = [self browseMetaDataWithMediaObject:item];
    
    // get uri
    NSString *uri = [self getUriForItem:(MediaServer1ItemObject *)item];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return UPNP_Error_RendererError;
    }
    else if (uri == nil)    // no uri for folder
    {
        return UPNP_Error_NoUriForFolder;
    }
    
    if (queueUris.count <= 0)   // no queue uri
    {
        return UPNP_Error_Sonos_NoQueueUri;
    }
    
    // TODO: find out action for querying the number of items in the playlist so we can enqueue at the end
    NSString *firstTrack = @"1";            // place the track as the first in the queue
    NSString *nextTrack = @"2";             // next track is track nr 2
    NSString *trackNumberInQueue = @"1";    // go to track nr. 1 in queue
    
    // add the uri of a item to the queue
    [[renderer avTransport] AddURIToQueueWithInstanceID:UPNP_DEFAULT_INSTANCE_ID URI:uri MetaData:[metaData XMLEscape] DesiredFirstTrackNumberEnqueued:firstTrack EnqueueAsNext:nextTrack];
    
    // play the current queue
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:queueUris.firstObject CurrentURIMetaData:@""];
    
    // seek to the track
    [[renderer avTransport] SeekWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Unit:@"TRACK_NR" Target:trackNumberInQueue];
    
    // play the track
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];
    
    return UPNP_Error_OK;
}

// add playlist/folder to queue and play the playlist/folder
- (UPNP_Error)playPlaylistOrQueue: (MediaServer1ContainerObject *)container
{
    if (renderer == nil || server == nil)
    {
        return UPNP_Error_NoRendererServer;
    }
    
    //Lazy Observer attach
    [self lazyObserverAttachRenderingControlService];
    
    // get metaData
    NSString *metaData = [self browseMetaDataWithMediaObject:container];
    
    // get uri
    NSString *uri = [self getUriForContainer:container];
    
    if ([uri isEqualToString:@"error"])     // render can not play object with this uri
    {
        return UPNP_Error_RendererError;
    }
    else if (uri == nil)    // no uri for folder
    {
        return UPNP_Error_NoUriForFolder;
    }
    
    if (queueUris.count <= 0)   // no queue uri
    {
        return UPNP_Error_Sonos_NoQueueUri;
    }
    
    NSString *firstTrack = @"0";            // place the track as the first in the queue
    NSString *nextTrack = @"1";             // next track is track nr 2
    NSString *trackNumberInQueue = @"1";    // go to track nr. 1 in queue
    
    // TODO: should queue be cleared before adding items? --> need to find out UPNP action for this
    
    // add the uri of a item to the queue
    [[renderer avTransport] AddURIToQueueWithInstanceID:UPNP_DEFAULT_INSTANCE_ID URI:uri MetaData:[metaData XMLEscape] DesiredFirstTrackNumberEnqueued:firstTrack EnqueueAsNext:nextTrack];
    
    // play the current queue
    [[renderer avTransport] SetAVTransportURIWithInstanceID:UPNP_DEFAULT_INSTANCE_ID CurrentURI:queueUris.firstObject CurrentURIMetaData:@""];
    
    // seek to the track
    [[renderer avTransport] SeekWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Unit:@"TRACK_NR" Target:trackNumberInQueue];
    
    // play the track
    [[renderer avTransport] PlayWithInstanceID:UPNP_DEFAULT_INSTANCE_ID Speed:UPNP_DEFAULT_PLAY_SPEED];
    
    return UPNP_Error_OK;
}


#pragma mark - helper functions

- (NSArray *)supportedItemProtocols
{
    return [[super supportedItemProtocols] arrayByAddingObjectsFromArray:SONOS_ITEM_PROTOCOLS];
}

- (NSArray *)supportedContainerProtocols
{
    return [[super supportedContainerProtocols] arrayByAddingObjectsFromArray:SONOS_CONTAINER_PROTOCOLS];
}

// returns YES, if item is a radio
+ (BOOL)canPlayRadio: (MediaServer1BasicObject *)object
{
    NSArray *supportedRadioProtocols = SONOS_RADIO_PROTOCOLS;
    
    for (NSString *uri in supportedRadioProtocols)
    {
        NSRange range = [[(MediaServer1ItemObject *)object uri] rangeOfString:uri options:NSCaseInsensitiveSearch];
        
        if(range.location != NSNotFound)
        {
            return YES;
        }
    }
    
    return NO;
}



#pragma mark -
#pragma mark - Content Directory

// get the meta data of a radio
/*
 error code:
 nil    no meta data for radio
 */
- (NSString *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem
{
    NSMutableArray *metaDataRadio = [[NSMutableArray alloc] init];
    
    NSString *metaData = [self browseMetaDataWithMediaObject:mediaItem];
    
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


// find the uri for the queue
// FIXME: this has only been tested with one Sonos and might not work with other types
/*
 error code:
 nil    no queue or uri for queue
 */
- (void)getQueueOfMediaDirectoryOnServerWithRootID: (NSString *)rootid
{
    NSMutableArray *queueContainer = [NSMutableArray new];
    
    NSArray *mediaObjects = [self browseContentForRootID:rootid];
    
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
                        [queueUris addObject:container.uris[0]];
                    }
                }
            }
            else if (container.uris.count > 0)
            {
                if (rangeUri.location != NSNotFound)
                {
                    [queueUris addObject:container.uris[0]];
                }
            }
        }
    }
    
    if (queueUris.count <= 0)
    {
        for (MediaServer1ContainerObject *container in queueContainer)
        {
            [self getQueueOfMediaDirectoryOnServerWithRootID:container.objectID];
        }
    }
}


@end
