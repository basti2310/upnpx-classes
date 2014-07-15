//
//  UPNPDiscovery.h
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 10.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>


//---- start, stop, refresh the upnp discovery ----//


// Documentation: upnpx - Open Source Mac OS X / iOS Cocoa UPnP Stack
// https://code.google.com/p/upnpx/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial


@interface UPNPDiscovery : NSObject

@property (nonatomic, readonly) NSArray *upnpDevices;
@property (nonatomic, readonly) NSArray *upnpServers;
@property (nonatomic, readonly) NSArray *upnpRenderers;


// Returns the shared, started instance of UPNPDiscovery.
+ (instancetype)instance;

// refresh the arry with the devices
- (void)refreshUPnPDeviceSearch;

// stop searching for devices
// doesn't work, Error: Socket error!
- (void)stopUPnPDeviceSearch;

@end
