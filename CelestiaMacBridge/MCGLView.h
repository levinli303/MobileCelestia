//
// GLView.h
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCGLView : NSOpenGLView

@property (nonatomic, nullable) void (^drawHandler)(void);
@property (nonatomic, nullable) void (^sizeChangeHandler)(NSSize);

- (nullable instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled wantsBestResolution:(BOOL)wantsBestResolution;

@end

NS_ASSUME_NONNULL_END
