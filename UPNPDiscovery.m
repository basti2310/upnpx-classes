//
//  UPNPDiscovery.m
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 10.07.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "UPNPDiscovery.h"
#import "UPnPManager.h"


@interface UPNPDiscovery ()

@property (nonatomic, strong) UPnPDB *db;

@end


@implementation UPNPDiscovery
{
    NSMutableArray *_upnpServers;
    NSMutableArray *_upnpRenderers;
}

@synthesize upnpServers = _upnpServers;
@synthesize upnpRenderers = _upnpRenderers;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.db = nil;
        _upnpDevices = nil;
        _upnpRenderers = [NSMutableArray new];
        _upnpServers = [NSMutableArray new];
    }
    
    return self;
}

// start searching for devices and save them into upnpDevices
// https://code.google.com/p/upnpx/wiki/TutorialDiscovery
- (void)startUPnPDeviceSearch
{
    NSLog(@"start searching ...");
    
    _upnpServers = [[NSMutableArray alloc] init];
    _upnpRenderers = [[NSMutableArray alloc] init];
    
    // Get a pointer to the discovery database via the UPnPManager,
    // register yourself as an observer and tell the SSDP implementation to search for devices by calling searchSSDP
    self.db = [[UPnPManager GetInstance] DB];
    
    _upnpDevices = [self.db rootDevices];
    
    [self.db addObserver:(UPnPDBObserver *)self]; // TODO: bad cast, this class is not a UPnPDBObserver!
    
    // optinal: set User Agent
    [[[UPnPManager GetInstance] SSDP] setUserAgentProduct:@"ayControl" andOS:@"iOS"];
    
    // Search for UPnP Devices
    [[[UPnPManager GetInstance] upnpEvents] start];
    [[[UPnPManager GetInstance] SSDP] startSSDP];
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

// refresh the arry with the devices
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
    [[[UPnPManager GetInstance] upnpEvents] stop];
    
    [self.db removeObserver:(UPnPDBObserver *)self];
    
    _upnpDevices = nil;
    self.db = nil;
}

// search for DMS and DMR
// https://code.google.com/p/upnpx/wiki/TutorialDescription
- (void)searchForRendererAndServer
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
    
    @synchronized (self)
    {
      //remove duplicates
      [_upnpServers setArray:[[NSSet setWithArray:servers] allObjects]];
      [_upnpRenderers setArray:[[NSSet setWithArray:renderer] allObjects]];
    }
}

#pragma mark - Protocol: UPnPDBObserver

- (void)UPnPDBUpdated:(UPnPDB *)sender
{
    NSLog(@"number of devices: %d", self.upnpDevices.count);
    [self searchForRendererAndServer];
}

- (void)UPnPDBWillUpdate:(UPnPDB *)sender
{

}

@end
