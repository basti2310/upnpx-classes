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

#define REFRESH_TIMER_INTERVAL  0.5
#define MAX_TIMER_CNT           5

@interface Start_Stop_Searching ()

@end

@implementation Start_Stop_Searching
{
    UPnPDB *db;
    
    BOOL refreshTag;
    
    NSUInteger upnpDevicesCntOld;
    
    NSTimer *refreshTimer;
    
    int timerCnt;
}

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
    db = [[UPnPManager GetInstance] DB];
    
    self.upnpDevices = [db rootDevices];
    
    [db addObserver:(UPnPDBObserver *)self];
    
    // optinal: set User Agent
    [[[UPnPManager GetInstance] SSDP] setUserAgentProduct:@"XBMC-Control/1.0" andOS:@"iOS"];
    
    // Search for UPnP Devices
    [[[UPnPManager GetInstance] upnpEvents] start]; // HACK
    [[[UPnPManager GetInstance] SSDP] startSSDP];
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

// refresh the arry with the devices
// works only, if a new device was discovered
- (void)refreshUPnPDeviceSearch
{
    NSLog(@"refresh ...");
    
    refreshTag = YES;
    upnpDevicesCntOld = self.upnpDevices.count;
    timerCnt = 0;
    [refreshTimer invalidate];
    refreshTimer = nil;
    // max. timer runtime = REFRESH_TIMER_INTERVAL * MAX_TIMER_CNT
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_TIMER_INTERVAL target:self selector:@selector(foundNewDevice) userInfo:nil repeats:YES];
    
    // Search for UPnP Devices
    [[[UPnPManager GetInstance] upnpEvents] start]; // HACK
    [[[UPnPManager GetInstance] SSDP] startSSDP];
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
}

- (void)foundNewDevice
{
    if (!refreshTag)    // found new device
    {
        refreshTag = NO;
        [refreshTimer invalidate];
        refreshTimer = nil;
        
        self.newDeviceTag = YES;
    }
    else
    {
        if (timerCnt == MAX_TIMER_CNT)  // no new devices were found
        {
            refreshTag = NO;
            [refreshTimer invalidate];
            refreshTimer = nil;
            
            self.newDeviceTag = NO;
        }
        
        timerCnt++;
    }
}

// stop searching for devices
// doesn't work, Error: Socket error!
- (void)stopUPnPDeviceSearch
{
    NSLog(@"stop searching ...");
    
    [[[UPnPManager GetInstance] SSDP] stopSSDP];
    [[[UPnPManager GetInstance] upnpEvents] stop];  // HACK
    
    [db removeObserver:(UPnPDBObserver *)self];
    
    self.upnpDevices = nil;
    db = nil;
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
        NSLog(@"Device: %@", device.friendlyName);
        
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
        {
            NSLog(@"Media Server 1");
            [servers addObject:(MediaServer1Device *)device];
        }
        else if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaRenderer:1"])
        {
            NSLog(@"Media Renderer 1");
            [renderer addObject:(MediaRenderer1Device *)device];
        }
    }
    
    //remove dublicates and write to the property
    [self.upnpServers setArray:[[NSSet setWithArray:servers] allObjects]];
    [self.upnpRenderer setArray:[[NSSet setWithArray:renderer] allObjects]];
    
    // search for new devices
    if (refreshTag && (upnpDevicesCntOld < self.upnpDevices.count))    // found new device
    {
        refreshTag = NO;
    }
}

#pragma mark - Protocol: UPnPDBObserver

// device array will update
- (void)UPnPDBWillUpdate:(UPnPDB *)sender
{
    NSLog(@"will update");
}

// device array updated
- (void)UPnPDBUpdated:(UPnPDB *)sender
{
    NSLog(@"updated");
    [self performSelectorOnMainThread:@selector(searchForDevices) withObject:nil waitUntilDone:YES];
}

@end
