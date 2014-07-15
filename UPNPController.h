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

#define UPNP_DEFAULT_INSTANCE_ID    @"0"
#define UPNP_DEFAULT_ROOT_ID        @"0"

#define UPNP_DEFAULT_CONTENT_BROWSEFLAG              @"BrowseDirectChildren"
#define UPNP_DEFAULT_METADAT_BROWSEFLAG              @"BrowseMetadata"
#define UPNP_DEFAULT_BROWSE_FILTER                   @"*"
#define UPNP_DEFAULT_BROWSE_STARTINGINDEX            @"0"
#define UPNP_DEFAULT_CONTENT_BROWSE_REQUESTEDCOUNT   @"0"
#define UPNP_DEFAULT_METADATA_BROWSE_REQUESTEDCOUNT  @"1"
#define UPNP_DEFAULT_BROWSE_SORTCRITERIA             @"+dc:title"

#define UPNP_DEFAULT_PLAY_MODE   @"NORMAL"
#define UPNP_DEFAULT_PLAY_SPEED  @"1"

#define UPNP_KEY_CURRENT_TRACK      @"currentTrack"
#define UPNP_KEY_TRACK_DURATION     @"trackDuration"
#define UPNP_KEY_TRACK_METADATA     @"trackMetaData"
#define UPNP_KEY_TRACK_URI          @"trackURI"
#define UPNP_KEY_REL_TIME           @"relTime"
#define UPNP_KEY_ABS_TIME           @"absTime"
#define UPNP_KEY_REL_COUNT          @"relCount"
#define UPNP_KEY_ABS_COUNT          @"absCount"
#define UPNP_KEY_ITEM_OBJECT        @"MediaServer1ItemObject"

#define UPNP_KEY_VOLUME         @"Volume"
#define UPNP_KEY_VOLUME_MIN     @"VolumeMin"
#define UPNP_KEY_VOLUME_MAX     @"VolumeMax"

#define UPNP_KEY_VOLUME_DB         @"VolumeDB"
#define UPNP_KEY_VOLUME_DB_MIN     @"VolumeDBMin"
#define UPNP_KEY_VOLUME_DB_MAX     @"VolumeDBMax"

#define UPNP_KEY_A_ARG_TYPE_CHANNEL     @"A_ARG_TYPE_Channel"

#define UPNP_KEY_TRANSPORT_STATUS   @"TransportStatus"
#define UPNP_KEY_TRANSPORT_STATE    @"TransportState"
#define UPNP_STATE_ERROR_OCCURRED   @"ERROR_OCCURRED"
#define UPNP_STATE_STOPPED          @"STOPPED"



typedef NS_ENUM(NSInteger, UPNPRendererType)
{
    UPNPRendererType_Generic,
    UPNPRendererType_Sonos
};

typedef NS_ENUM(NSInteger, UPNP_Error)
{
    UPNP_Error_OK,
    UPNP_Error_NoRendererServer,
    UPNP_Error_UseOtherFunction,
    UPNP_Error_NoUriForItem,
    UPNP_Error_FalseProtocolType,
    UPNP_Error_RendererError,
    UPNP_Error_NoUriForFolder,
    
    UPNP_Error_Sonos_NoMetaData,
    UPNP_Error_Sonos_NoQueueUri
};



@interface UPNPController : NSObject
{
    @protected
    MediaServer1Device *server;
    MediaRenderer1Device *renderer;
}

// TODO: move to UI layer, not needed here
@property (nonatomic, strong) MediaServer1BasicObject *currentBasicObject;


#pragma mark -
#pragma mark - Initialisation

- (instancetype)initWithRenderer: (MediaRenderer1Device *)rend andServer: (MediaServer1Device *)serv;

// TODO: move to category on BasicUPnPDevice
+ (UPNPRendererType)deviceType: (BasicUPnPDevice *)device;



#pragma mark -
#pragma mark - Content Directory

// Documentation: ContentDirectory:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

// get the folder/file hierarchy
// rootID = selectedObject.objectID or "0" for hierarchy root
- (NSArray *)browseContentForRootID: (NSString *)rootid;



#pragma mark -
#pragma mark - AVTransport

// Documentation: AVTransport:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

// play an item
- (UPNP_Error)play: (MediaServer1BasicObject *)item;

// play a container (folder/playlist)
- (UPNP_Error)playFolderPlaylist: (MediaServer1ContainerObject *)object;

// if pause -> replay
- (UPNP_Error)replay;

// stop
- (UPNP_Error)stop;

// pause
- (UPNP_Error)pause;

// next (works only with playlist/folder)
- (UPNP_Error)next;

// previous (works only with playlist/folder)
- (UPNP_Error)previous;

// seek
// mode: p. 10 & p. 15 - AVTransport:1 Service Template Version 1.01    example: @"REL_TIME"
// target: p. 16 - AVTransport:1 Service Template Version 1.01
- (UPNP_Error)seekWithMode: (NSString *)mode andTarget: (NSString *)target;

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

// TODO: move to helper or NSString category

// converts a time string (01:45:33) into a float value
+ (int)timeStringIntoInt: (NSString *)timeString;

// converts a float value into a time string (01:45:33)
+ (NSString *)intIntoTimeString: (int)value;



#pragma mark -
#pragma mark - Rendering

// Documentation: RenderingControl:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

// Default channel string: @"Master"

// set mute for channel
- (UPNP_Error)setMute: (BOOL)mute forChannel: (NSString *)channel;

// get mute for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getMuteForChannel: (NSString *)channel;

// set volume for channel
- (UPNP_Error)setVolume: (NSUInteger)vol forChannel: (NSString *)channel;

// get volume for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getVolumeForChannel: (NSString *)channel;

// set brightness
- (UPNP_Error)setBrightness: (NSUInteger)brigh;

// get brightness
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getBrightness;

// set volume DB for channel
- (UPNP_Error)setVolumeDB: (float)volDB forChannel: (NSString *)channel;

// get volume DB for channel
/*
 error code:
 nil  no renderer
 */
- (NSNumber *)getVolumeDBForChannel: (NSString *)channel;

// get volume DB range for channel
/*
 error code:
 nil  no renderer
 */
- (NSDictionary *)getVolumeDBRangeForChannel: (NSString *)channel;



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

// Valid URNs: URN_SERVICE_RENDERING_CONTROL_1, URN_SERVICE_CONTENT_DIRECTORY_1, URN_SERVICE_AVTRANSPORT_1

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
