//
//  StateVariableRangeList.h
//  UPnP-Controller
//
//  Created by Sebastian Peischl on 02.06.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StateVariableRangeList : NSObject

+ (NSDictionary *)getVolumeMinMax;
+ (NSArray *)getChannelList;
+ (NSDictionary *)getVolumeDBMinMax;

@end
