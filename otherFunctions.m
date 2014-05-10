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

@end
