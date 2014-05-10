//
//  Rendering.m
//  
//
//  Created by Sebastian Peischl on 05.04.14.
//  Copyright (c) 2014 easyMOBIZ. All rights reserved.
//

#import "Rendering.h"
#import "BasicUPnPService.h"

static Rendering *rendering = nil;
static NSString *iid = @"0";                // p. 16 - AVTransport:1 Service Template Version 1.01
                                            // p. 6/1.2 - RenderingControl:1 Service Template Version 1.01
                                            // p. 17 - RenderingControl:1 Service Template Version 1.01
                                            // p. 39/2.5.1 - RenderingControl:1 Service Template Version 1.01

static NSString *channel = @"Master";       // p. 10 - RenderingControl:1 Service Template Version 1.01
                                            // p. 16 - RenderingControl:1 Service Template Version 1.01

@interface Rendering ()

@end

@implementation Rendering
{
    MediaRenderer1Device *renderer;
}

#pragma mark - Initialisation

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        renderer = nil;
    }

    return self;
}

+ (Rendering *)getInstance
{
    if (rendering == nil)
        rendering = [[Rendering alloc] init];
    
    return rendering;
}

- (void)setRenderer: (MediaRenderer1Device *)render
{
    MediaRenderer1Device *oldRender = renderer;
    
    // remove old Observer
    if (oldRender != nil)
    {
        if ([[oldRender renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == YES)
            [[oldRender renderingControlService] removeObserver:(BasicUPnPServiceObserver *)self];
    }
    
    renderer = render;
    
    // add new Observer
    if (renderer != nil)
    {
        if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
            [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    }
}

#pragma mark - Rendering Functions

- (void)setMute: (NSString *)mut
{
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] SetMuteWithInstanceID:iid Channel:channel DesiredMute:mut];        // p. 34 - RenderingControl:1 Service Template Version 1.01
}

- (NSString *)getMute
{
    NSMutableString *outMute = [[NSMutableString alloc] init];

    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] GetMuteWithInstanceID:iid Channel:channel OutCurrentMute:outMute];     // p. 33 - RenderingControl:1 Service Template Version 1.01
    
    return [outMute copy];
}

- (void)setVolume: (NSString *)vol
{
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] SetVolumeWithInstanceID:iid Channel:channel DesiredVolume:vol];        // p. 35 - RenderingControl:1 Service Template Version 1.01
}

- (NSString *)getVolume
{
    NSMutableString *outVolume = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] GetVolumeWithInstanceID:iid Channel:channel OutCurrentVolume:outVolume];       // p. 35 - RenderingControl:1 Service Template Version 1.01
    
    return [outVolume copy];
}

- (void)setBrightness: (NSString *)brigh
{
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] SetBrightnessWithInstanceID:iid DesiredBrightness:brigh];      // p. 22 - RenderingControl:1 Service Template Version 1.01
}

- (NSString *)getBrightness
{
    NSMutableString *outBrightness = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] GetBrightnessWithInstanceID:iid OutCurrentBrightness:outBrightness];       // p. 22 - RenderingControl:1 Service Template Version 1.01
    
    return [outBrightness copy];
}

- (void)setVolumeDB: (NSString *)volDB
{
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] SetVolumeDBWithInstanceID:iid Channel:channel DesiredVolume:volDB];        // p. 36 - RenderingControl:1 Service Template Version 1.01
}

- (NSString *)getVolumeDB
{
    NSMutableString *outVolDB = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] GetVolumeDBWithInstanceID:iid Channel:channel OutCurrentVolume:outVolDB];      // p. 36 - RenderingControl:1 Service Template Version 1.01
    
    return [outVolDB copy];
}

- (NSString *)getVolumeDBRange
{
    NSMutableString *outVolDBmin = [[NSMutableString alloc] init];
    NSMutableString *outVolDBmax = [[NSMutableString alloc] init];
    
    // Lazy Observer attach
    if ([[renderer renderingControlService] isObserver:(BasicUPnPServiceObserver *)self] == NO)
        [[renderer renderingControlService] addObserver:(BasicUPnPServiceObserver *)self];
    
    [[renderer renderingControl] GetVolumeDBRangeWithInstanceID:iid Channel:channel OutMinValue:outVolDBmin OutMaxValue:outVolDBmax];       // p. 37 - RenderingControl:1 Service Template Version 1.01
    
    return [NSString stringWithFormat:@"%@ - %@", outVolDBmin, outVolDBmax];
}

#pragma mark - Eventing

// https://code.google.com/p/upnpx/wiki/TutorialEventing
- (void)UPnPEvent: (BasicUPnPService *)sender events:(NSDictionary *)events
{
    NSLog(@"Events: %@", events);
    
    /*
    if (sender == [renderer renderingControlService])
    {
        NSString *state = [events objectForKey:@"Mute"];
        
        NSLog(@"Mute-State: %@", state);
    }
     */
}

@end

