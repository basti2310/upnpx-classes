//
//  Start_Stop_Searching.h
//  
//
//  Created by Sebastian Peischl on 26.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>

// Documentation: upnpx - Open Source Mac OS X / iOS Cocoa UPnP Stack
// https://code.google.com/p/upnpx/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

@interface Start_Stop_Searching : NSObject

@property (nonatomic, strong) NSArray *upnpDevices;
@property (nonatomic, strong) NSMutableArray *upnpServers;
@property (nonatomic, strong) NSMutableArray *upnpRenderer;

@property (nonatomic) BOOL newDeviceTag;    // observe this property after refresh, YES = found new device

// start searching for devices and save them into a array
- (void)startUPnPDeviceSearch;

// refresh the arry with the devices
// works only, if a new device was discovered
- (void)refreshUPnPDeviceSearch;

// stop searching for devices
// doesn't work, Error: Socket error!
- (void)stopUPnPDeviceSearch;


@end



