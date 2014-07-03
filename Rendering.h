//
//  Rendering.h
//  
//
//  Created by Sebastian Peischl on 05.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaRenderer1Device.h"

// Documentation: RenderingControl:1 Service Template Version 1.01
// http://upnp.org/specs/av/av1/
// upnpx-Tutorial: https://code.google.com/p/upnpx/wiki/tutorial

@interface Rendering : NSObject

+ (Rendering *)getInstance;
- (void)setRenderer: (MediaRenderer1Device *)render;

- (int)setMute: (NSString *)mut;
- (NSString *)getMute;

- (int)setVolume: (NSString *)vol;
- (NSString *)getVolume;

- (int)setBrightness: (NSString *)brigh;
- (NSString *)getBrightness;

- (int)setVolumeDB: (NSString *)volDB;
- (NSString *)getVolumeDB;

- (NSString *)getVolumeDBRange;

@end
