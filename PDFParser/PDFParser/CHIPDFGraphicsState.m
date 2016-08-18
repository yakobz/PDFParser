//
//  CHIPDFGraphicsState.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFGraphicsState.h"

@implementation CHIPDFGraphicsState

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self reset];
    }
    
    return self;
}

- (void)reset {
    self.ctm = CGAffineTransformIdentity;
    self.colorSpace = CGColorSpaceCreateDeviceGray();
    self.colorStroke = CGColorCreateGenericGray(0, 1);
    self.colorFill = CGColorCreateGenericGray(0, 1);
    self.textState = [[CHIPDFTextState alloc] init];
    self.lineWidth = 1.0;
    self.lineCap = 0;
    self.lineJoin = 0;
    self.dashPattern = nil;
    self.blendMode = kCGBlendModeNormal;
    self.softMask = nil;
    self.alphaConstant = 1.0;
    self.alphaSource = NO;
}

- (id)copyWithZone:(NSZone *)zone {
    CHIPDFGraphicsState *newObject = [[CHIPDFGraphicsState alloc] init];
    newObject.ctm = self.ctm;
    newObject.colorSpace = CGColorSpaceRetain(self.colorSpace);
    newObject.colorStroke = CGColorRetain(self.colorStroke);
    newObject.colorFill = CGColorRetain(self.colorFill);
    newObject.textState = self.textState;
    newObject.lineWidth = self.lineWidth;
    newObject.lineCap = self.lineCap;
    newObject.lineJoin = self.lineJoin;
    newObject.dashPattern = self.dashPattern;
    newObject.blendMode = self.blendMode;
    newObject.softMask = self.softMask;
    newObject.alphaConstant = self.alphaConstant;
    newObject.alphaSource = self.alphaSource;
    return newObject;
}

- (void)concatenateMatrix:(CGAffineTransform)matrix {
    self.ctm = CGAffineTransformConcat(self.ctm, matrix);
}

- (void)dealloc {
    if (self.colorSpace) {
        CGColorSpaceRelease(self.colorSpace);
    }
    if (self.colorStroke) {
        CGColorRelease(self.colorStroke);
    }
    if (self.colorFill) {
        CGColorRelease(self.colorFill);
    }
}

@end
