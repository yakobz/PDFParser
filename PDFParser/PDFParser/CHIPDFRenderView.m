//
//  CHIPDFRenderView.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFRenderView.h"
#import <QuartzCore/QuartzCore.h>
#import "CHIPDFPath.h"
#import "CHIPDFGraphicsState.h"

@implementation CHIPDFRenderView

- (void)setClipPath:(CHIPDFPath *)clipPath {
    _clipPath = clipPath;
    
    CAShapeLayer * layer = [CAShapeLayer layer];
    layer.path = clipPath.path;
    self.wantsLayer = YES;
    self.layer.mask = layer;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"class: %@, frame: %@", [self className], NSStringFromRect(self.frame)];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.drawPath) {
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextAddPath(context, self.drawPath.path);
        CHIPDFGraphicsState *graphicsState = self.drawPath.graphicsState;

        if (self.drawPath.fill) {
            CGContextSetFillColorSpace(context, graphicsState.colorSpace);
            CGContextSetFillColorWithColor(context, graphicsState.colorFill);
            CGContextFillPath(context);
        }
        
        if (self.drawPath.stroke) {
            CGContextSetStrokeColorSpace(context, graphicsState.colorSpace);
            CGContextSetStrokeColorWithColor(context, graphicsState.colorStroke);
            CGContextStrokePath(context);
        }
    }
}

@end
