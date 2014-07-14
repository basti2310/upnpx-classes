//
//  UPNPController.h
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 10.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaServer1Device.h"
#import "MediaRenderer1Device.h"


#define URN_SERVICE_RENDERING_CONTROL_1     @"urn:schemas-upnp-org:service:RenderingControl:1"
#define URN_SERVICE_CONTENT_DIRECTORY_1     @"urn:schemas-upnp-org:service:ContentDirectory:1"
#define URN_SERVICE_AVTRANSPORT_1           @"urn:schemas-upnp-org:service:AVTransport:1"

#define UPNP_DEFAULT_INSTANCE_ID  @"0"


@interface UPNPController : NSObject
{
    @protected
    MediaServer1Device *server;
    MediaRenderer1Device *renderer;
}


@property (nonatomic, strong) MediaServer1BasicObject *currentBasicObject;


#pragma mark -
#pragma mark - Initialisation

- (instancetype)initWithRenderer: (MediaRenderer1Device *)rend andServer: (MediaServer1Device *)serv;



#pragma mark -
#pragma mark - Content Directory

// Documentation: ContentDirectory:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

// get the folder/file hierarchy
- (NSArray *)browseContentForRootID: (NSString *)rootid;



#pragma mark -
#pragma mark - AVTransport

// Documentation: AVTransport:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

// play an item
/*
 error code:
 1   no renderer or server
 2   use other function -> - (int)playPlaylist: (MediaServer1ContainerObject *)object
 3   no uri for item
 4   false protocol type for uri
 */
- (int)play: (MediaServer1BasicObject *)item;

// play a container (folder/playlist)
/*
 error code:
 1   no renderer or server
 2   render can not play object with this uri
 3   no uri for folder
 */
- (int)playFolderPlaylist: (MediaServer1ContainerObject *)object;

// if pause -> replay
/*
 error code:
 1  no renderer
 */
- (int)replay;

// stop
/*
 error code:
 1  no renderer
 */
- (int)stop;

// pause
/*
 error code:
 1  no renderer
 */
- (int)pause;

// next (works only with playlist/folder)
/*
 error code:
 1  no renderer
 */
- (int)next;

// previous (works only with playlist/folder)
/*
 error code:
 1  no renderer
 */
- (int)previous;

// seek
// mode: p. 10 & p. 15 - AVTransport:1 Service Template Version 1.01    example: @"REL_TIME"
// target: p. 16 - AVTransport:1 Service Template Version 1.01
/*
 error code:
 1  no renderer
 */
- (int)seekWithMode: (NSString *)mode andTarget: (NSString *)target;

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
- (NSDictionary *)getPositionAndTrackInfo;


#pragma mark - helper functions

// converts a time string (01:45:33) into a float value
- (int)timeStringIntoInt: (NSString *)timeString;

// converts a float value into a time string (01:45:33)
- (NSString *)intIntoTimeString: (int)value;



#pragma mark -
#pragma mark - Rendering

// Documentation: RenderingControl:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial


// set mute for channel
/*
 error code:
 1  no renderer
 */
- (int)setMute: (NSString *)mut forChannel: (NSString *)channel;

// get mute for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getMuteForChannel: (NSString *)channel;

// set volume for channel
/*
 error code:
 1  no renderer
 */
- (int)setVolume: (NSString *)vol forChannel: (NSString *)channel;

// get volume for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeForChannel: (NSString *)channel;

// set brightness
/*
 error code:
 1  no renderer
 */
- (int)setBrightness: (NSString *)brigh;

// get brightness
/*
 error code:
 nil  no renderer
 */
- (NSString *)getBrightness;

// set volume DB for channel
/*
 error code:
 1  no renderer
 */
- (int)setVolumeDB: (NSString *)volDB forChannel: (NSString *)channel;

// get volume DB for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeDBForChannel: (NSString *)channel;

// get volume DB range for channel
/*
 error code:
 nil  no renderer
 */
- (NSString *)getVolumeDBRangeForChannel: (NSString *)channel;



#pragma mark -
#pragma mark - StateVariableRangeList

// get volume min & max
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeMinMax;

// get channel list
/*
 error code:
 nil  no renderer
 */
- (NSArray *)getChannelList;

// get volume db min & max
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeDBMinMax;



#pragma mark -
#pragma mark - ActionList

// get all available render actions for a urn
- (NSArray *)getAvailableRenderActionsForUrn: (NSString *)urn;

// get all available server actions for a urn
- (NSArray *)getAvailableServerActionsForUrn: (NSString *)urn;



#pragma mark -
#pragma mark - internal API

- (NSArray *)supportedItemProtocols;
- (NSArray *)supportedContainerProtocols;

- (NSString *)getUriForItem: (MediaServer1ItemObject *)item;
- (NSString *)getUriForContainer: (MediaServer1ContainerObject *)container;

- (NSString *)browseMetaDataWithMediaObject: (MediaServer1BasicObject *)object;

- (void)lazyObserverAttachAVTransportService;
- (void)lazyObserverAttachRenderingControlService;



@end
