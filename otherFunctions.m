//
//  otherFunctions.m
//  
//
//  Created by Sebastian Peischl on 27.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "otherFunctions.h"
#import "UPnPManager.h"
#import "MediaRenderer1Device.h"
#import "AVTransport.h"


@interface otherFunctions ()

@end


@implementation otherFunctions
{

}

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

// returns YES if the available action list contains a certain action
+ (BOOL)actionList: (NSArray *)actions containsAction: (NSString *)actionName
{
    return [actions containsObject:actionName];
}

// converts a time string (01:45:33) into a float value
+ (float)timeStringIntoFloat: (NSString *)timeString
{
    NSScanner *timeScanner = [NSScanner scannerWithString:timeString];
    int hours, minutes, sec;
    
    [timeScanner scanInt:&hours];
    [timeScanner scanString:@":" intoString:nil];
    [timeScanner scanInt:&minutes];
    [timeScanner scanString:@":" intoString:nil];
    [timeScanner scanInt:&sec];
    
    return (hours * 3600 + minutes * 60 + sec);
}

// converts a float value into a time string (01:45:33)
+ (NSString *)floatIntoTimeString: (int)value
{
    int hour, minutes, sec;
    NSString *hourStr, *minStr, *secStr;
    
    hour = value / 3600;
    minutes = (value % 3600) / 60;
    sec = (value % 3600) - (minutes * 60);
    
    if (hour < 10)
        hourStr = [NSString stringWithFormat:@"0%d", hour];
    else
        hourStr = [NSString stringWithFormat:@"%d", hour];
    
    if (minutes < 10)
        minStr = [NSString stringWithFormat:@"0%d", minutes];
    else
        minStr = [NSString stringWithFormat:@"%d", minutes];
    
    if (sec < 10)
        secStr = [NSString stringWithFormat:@"0%d", sec];
    else
        secStr = [NSString stringWithFormat:@"%d", sec];
    
    
    return [NSString stringWithFormat:@"%@:%@:%@", hourStr, minStr, secStr];
}

@end
