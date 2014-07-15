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
/*
 error code:
 1   no renderer or server
 2   render can not play object with this uri
 3   no uri for item
 4   not meta data for radio
 */
- (int)playRadio: (MediaServer1ItemObject *)item;

// add item to queue and play the item
/*
 error code:
 1   no renderer or server
 2   render can not play object with this uri
 3   no uri for item
 4   no uri for queue
 */
- (int)playItemWithQueue: (MediaServer1BasicObject *)item;

// add playlist/folder to queue and play the playlist/folder
/*
 error code:
 1   no renderer or server
 2   render can not play object with this uri
 3   no uri for folder
 4   no uri for queue
 */
- (int)playPlaylistOrQueue: (MediaServer1ContainerObject *)container;


#pragma mark - helper functions

// returns YES, if item is a radio
- (BOOL)isObjectRadio: (MediaServer1BasicObject *)object;



#pragma mark -
#pragma mark - Content Directory

// get the meta data of a radio
/*
 error code:
 nil    no meta data for radio
 */
- (NSString *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem;



@end
