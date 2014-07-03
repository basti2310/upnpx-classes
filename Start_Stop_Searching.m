//
//  Start_Stop_Searching.m
//  
//
//  Created by Sebastian Peischl on 26.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "Start_Stop_Searching.h"
#import "UPnPManager.h"
#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "MediaRenderer1Device.h"
#import "otherFunctions.h"
#import "UPnPDB.h"


@interface Start_Stop_Searching ()

@property (nonatomic, strong) UPnPDB *db;

@end

@implementation Start_Stop_Searching

#pragma mark - Initialisation

// start searching for devices and save them into a array
// https://code.google.com/p/upnpx/wiki/TutorialDiscovery
- (void)startUPnPDeviceSearch
{
    NSLog(@"start searching ...");
    
    // initialisation of the arrays
    self.upnpServers = [[NSMutableArray alloc] init];
    self.upnpRenderer = [[NSMutableArray alloc] init];
    
    // Get a pointer to the discovery database via the UPnPManager,
    // register yourself as an observer and tell the SSDP implementation to search for devices by calling searchSSDP
    self.db = [[UPnPManager GetInstance] DB];
    
    self.upnpDevices = [self.db rootDevices];
    
    [self.db addObserver:(UPnPDBObserver *)self];
    
    // optinal: set User Agent
    [[[UPnPManager GetInstance] SSDP] setUserAgentProduct:@"XBMC-Control/1.0" andOS:@"iOS"];
    
    // Search for UPnP Devices
    [[[UPnPManager GetInstance] upnpEvents] start];
    [[[UPnPManager GetInstance] SSDP] startSSDP];
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

// refresh the arry with the devices
// works only, if a new device was discovered
- (void)refreshUPnPDeviceSearch
{
    NSLog(@"refresh ...");
    
    // Search for UPnP Devices
    [[[UPnPManager GetInstance] upnpEvents] start];
    [[[UPnPManager GetInstance] SSDP] startSSDP];
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

// stop searching for devices
// doesn't work, Error: Socket error!
- (void)stopUPnPDeviceSearch
{
    NSLog(@"stop searching ...");
    
    [[[UPnPManager GetInstance] SSDP] stopSSDP];
    [[[UPnPManager GetInstance] upnpEvents] stop];  // HACK
    
    [self.db removeObserver:(UPnPDBObserver *)self];
    
    self.upnpDevices = nil;
    self.db = nil;
}

// search for DMS and DMR and save them into a array
// https://code.google.com/p/upnpx/wiki/TutorialDescription
- (void)searchForDevices
{
    NSMutableArray *servers = [[NSMutableArray alloc] init];
    NSMutableArray *renderer = [[NSMutableArray alloc] init];

    for (int i = 0; i < self.upnpDevices.count; i++)
    {
        BasicUPnPDevice *device = [self.upnpDevices objectAtIndex:i];
        
        if ([device.urn isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
        {
            [servers addObject:(MediaServer1Device *)device];
        }
        else if ([device.urn isEqualToString:@"urn:schemas-upnp-org:device:MediaRenderer:1"])
        {
            [renderer addObject:(MediaRenderer1Device *)device];
        }
    }
    
    //remove dublicates and write to the property
    [self.upnpServers setArray:[[NSSet setWithArray:servers] allObjects]];
    [self.upnpRenderer setArray:[[NSSet setWithArray:renderer] allObjects]];
}

#pragma mark - Protocol: UPnPDBObserver
 
- (void)UPnPDDeviceAdded:(UPnPDB*)sender device:(BasicUPnPDevice *) device
{
    NSLog(@"device added: %@", [otherFunctions nameOfUPnPDevice:device]);
    [self performSelectorOnMainThread:@selector(searchForDevices) withObject:nil waitUntilDone:YES];
}

- (void)UPnPDDeviceRemoved:(UPnPDB*)sender device:(BasicUPnPDevice *) device
{
    NSLog(@"device removed: %@", [otherFunctions nameOfUPnPDevice:device]);
    [self performSelectorOnMainThread:@selector(searchForDevices) withObject:nil waitUntilDone:YES];
}

@end
