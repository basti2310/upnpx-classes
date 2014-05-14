//
//  otherFunctions.h
//  
//
//  Created by Sebastian Peischl on 27.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface otherFunctions : NSObject

// urn list
enum urnServiceNames
{
    urnRenderingService,
    urnContentService,
    urnAVTransportService
};

// returns the name of a media device
+ (NSString *)nameOfUPnPDevice: (id)device;

// converts a folat value into a string
+ (NSString *)floatIntoString: (float)value;

// return available actions
+ (NSArray *)availableActionsForDevice: (id)device forUrn: (enum urnServiceNames)urn withNeededActions: (NSArray *)neededActions;

// returns all actions for one device
+ (NSArray *)listActionsForDevice: (id)device forUrn: (enum urnServiceNames)urn;

@end
