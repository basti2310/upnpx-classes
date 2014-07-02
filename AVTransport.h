//
//  AVTransport.h
//  
//
//  Created by Sebastian Peischl on 07.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaRenderer1Device.h"

// Documentation: AVTransport:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

@interface AVTransport : NSObject

+ (AVTransport *)getInstance;
- (void)setRenderer: (MediaRenderer1Device *)rend andServer: (MediaServer1Device *)serv;

- (int)play: (NSArray *)playli position: (int)pos;
- (int)playPlaylist: (MediaServer1ContainerObject *)object;
- (int)replay;
- (int)stop;
- (int)pause;
- (int)next;
- (int)previous;
- (int)seekWithMode: (NSString *)mode andTarget: (NSString *)target;
- (NSDictionary *)getPositionAndTrackInfo;

@end
