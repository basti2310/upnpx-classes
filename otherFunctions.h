//
//  otherFunctions.h
//  
//
//  Created by Sebastian Peischl on 27.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface otherFunctions : NSObject

// returns the name of a media device
+ (NSString *)nameOfUPnPDevice: (id)device;

// converts a folat value into a string
+ (NSString *)floatIntoString: (float)value;

@end
