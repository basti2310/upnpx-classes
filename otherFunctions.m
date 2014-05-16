//
//  otherFunctions.m
//  
//
//  Created by Sebastian Peischl on 27.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "otherFunctions.h"
#import "UPnPManager.h"

@implementation otherFunctions

// returns the name of a media device
+ (NSString *)nameOfUPnPDevice: (id)device
{
    BasicUPnPDevice *upnpDevice = device;
    return upnpDevice.friendlyName;
}

// converts a folat value into a string
+ (NSString *)floatIntoString: (float)value
{
    return [NSString stringWithFormat:@"%f", value];
}

// return available actions
+ (NSArray *)availableActionsForDevice: (id)device forUrn: (NSString *)urn withNeededActions: (NSArray *)neededActions
{
    return [self compareActions:[self listActionsForDevice:device forUrn:urn] withNeededActions:neededActions];
}

// returns all actions for one device
+ (NSArray *)listActionsForDevice: (id)device forUrn: (NSString *)urn
{
    device = (BasicUPnPDevice *)device;
    
    BasicUPnPService *serv = [device getServiceForType:urn];
    
    return [serv.actionList copy];
}

// compare actions with needed actions and returns actions which the app can use
+ (NSArray *)compareActions: (NSArray *)act withNeededActions: (NSArray *)neededActions
{
    NSMutableArray *actions = [NSMutableArray new];
    
    for (int i = 0; i < neededActions.count; i++)
    {
        if ([act containsObject:neededActions[i]])
            [actions addObject:neededActions[i]];
    }
    
    return [actions copy];
}

@end
