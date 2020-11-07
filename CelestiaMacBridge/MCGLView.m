//
// MCGLView.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "MCGLView.h"
#import <OpenGL/CGLTypes.h>
#import <OpenGL/gl.h>

@interface MCGLView ()

@property (nonatomic) BOOL msaaEnabled;

@end

@implementation MCGLView

- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled wantsBestResolution:(BOOL)wantsBestResolution {
    const NSOpenGLPixelFormatAttribute msaaAttrs[] = {
//        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize,
        (NSOpenGLPixelFormatAttribute)24,
        NSOpenGLPFASampleBuffers,
        (NSOpenGLPixelFormatAttribute)1,
        NSOpenGLPFASamples,
        (NSOpenGLPixelFormatAttribute)1,
        nil
    };
    const NSOpenGLPixelFormatAttribute noMsaaAttrs[] = {
//        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize,
        (NSOpenGLPixelFormatAttribute)24,
        nil
    };
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:msaaEnabled ? msaaAttrs : noMsaaAttrs];
    self = [super initWithFrame:NSZeroRect pixelFormat:pixelFormat];
    if (self) {
        _msaaEnabled = msaaEnabled;
        _drawHandler = nil;
        _sizeChangeHandler = nil;
        [self setupGL];
        [self setWantsBestResolutionOpenGLSurface:wantsBestResolution];
    }
    return self;
}

- (void)reshape {
    [super reshape];

    if (_sizeChangeHandler)
        _sizeChangeHandler(self.bounds.size);
}

- (void)update {
    [super update];

    if (_sizeChangeHandler)
        _sizeChangeHandler(self.bounds.size);
}

- (void)drawRect:(NSRect)dirtyRect {
    NSOpenGLContext *context = [self openGLContext];
    if (context && _drawHandler) {
        _drawHandler();
        [context flushBuffer];
    }
}

- (void)setupGL {
    NSOpenGLContext *context = [self openGLContext];
    if (!context) return;

    CGLContextObj obj = [context CGLContextObj];
    if (obj && CGLEnable(obj, (CGLContextEnable)313) == 0)
        NSLog(@"Multithreaded OpenGL enabled.");

    GLint swapInterval = 1;
    [context setValues:&swapInterval forParameter:NSOpenGLContextParameterSwapInterval];
    [context makeCurrentContext];

    if (_msaaEnabled)
        glEnable((GLenum)0x809D);
}

@end
