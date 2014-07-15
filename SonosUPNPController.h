//
//  SonosUPNPController.h
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 11.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "UPNPController.h"

@interface SonosUPNPController : UPNPController


#pragma mark -
#pragma mark - AVTransport

// play radio
- (UPNP_Error)playRadio: (MediaServer1ItemObject *)item;

// add item to queue and play the item
- (UPNP_Error)playItemWithQueue: (MediaServer1BasicObject *)item;

// add playlist/folder to queue and play the playlist/folder
- (UPNP_Error)playPlaylistOrQueue: (MediaServer1ContainerObject *)container;


#pragma mark - helper functions

// returns YES, if item is a radio
+ (BOOL)canPlayRadio: (MediaServer1BasicObject *)object;



#pragma mark -
#pragma mark - Content Directory

// get the meta data of a radio
/*
 error code:
 nil    no meta data for radio
 */
- (NSString *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem;



@end
