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
 3   no uri for folder
 */
- (int)play: (MediaServer1BasicObject *)item withQueueUri: (NSString *)queueUri;

// add playlist/folder to queue and play the playlist/folder
/*
 error code:
 1   no renderer or server
 2   render can not play object with this uri
 3   no uri for queue
 */
- (int)playPlaylistOrQueue: (MediaServer1ContainerObject *)container withQueueUri: (NSString *)queueUri;


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

// find the uri for the queue
/*
 error code:
 nil    no queue or uri for queue
 */
- (NSArray *)getQueueOfMediaDirectoryOnServerWithRootID: (NSString *)rootid;


@end
