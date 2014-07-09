//
//  StateVariableRangeList.m
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 02.06.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "StateVariableRangeList.h"
#import "StateVariable.h"
#import "StateVariableRange.h"
#import "StateVariableList.h"
#import "OtherFunctions.h"

@implementation StateVariableRangeList

+ (NSDictionary *)getVolumeMinMax
{
    BasicUPnPService *serv = [(BasicUPnPDevice *)GLB.renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableRange *range = [serv.stateVariables objectForKey:@"Volume"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min],           @"VolumeMin",
            [NSNumber numberWithInt:range.max],           @"VolumeMax",
            nil];
}

+ (NSArray *)getChannelList
{
    BasicUPnPService *serv = [(BasicUPnPDevice *)GLB.renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableList *list = [serv.stateVariables objectForKey:@"A_ARG_TYPE_Channel"];
    
    return list.list;
}

+ (NSDictionary *)getVolumeDBMinMax
{
    BasicUPnPService *serv = [(BasicUPnPDevice *)GLB.renderer getServiceForType:URN_SERVICE_RENDERING_CONTROL_1];
    StateVariableRange *range = [serv.stateVariables objectForKey:@"VolumeDB"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:range.min],           @"VolumeDBMin",
            [NSNumber numberWithInt:range.max],           @"VolumeDBMax",
            nil];
}

@end
