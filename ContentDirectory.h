//
//  ContentDirectory.h
//  
//
//  Created by Sebastian Peischl on 11.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaServer1Device.h"

// Documentation: ContentDirectory:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

@interface ContentDirectory : NSObject

+ (ContentDirectory *)getInstance;

- (NSArray *)browseContentWithDevice: (MediaServer1Device *)device andRootID: (NSString *)rootid;
- (NSString *)browseMetaDataWithMediaItem: (MediaServer1ItemObject *)mediaItem andDevice: (MediaServer1Device *)device;
- (NSString *)browseMetaDataWithMediaContainer: (MediaServer1ContainerObject *)mediaContainer andDevice: (MediaServer1Device *)device;
- (NSArray *)browseMetaDataForRadioWithMediaItem: (MediaServer1ItemObject *)mediaItem andDevice: (MediaServer1Device *)device;

@end
