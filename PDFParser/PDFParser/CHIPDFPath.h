//
//  CHIPDFPath.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 23.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHIPDFGraphicsState;

@interface CHIPDFPath : NSObject

@property (nonatomic, strong) NSMutableArray *pathArray;
@property (nonatomic, strong) NSString *svgPath;

@property (nonatomic) BOOL stroke;
@property (nonatomic) BOOL fill;
@property (nonatomic) BOOL finished;
@property (nonatomic, strong) CHIPDFGraphicsState *graphicsState;

- (void)moveToPoint:(NSPoint)point;
- (void)lineToPoint:(NSPoint)point;
- (void)addCurvePoint1:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3;
- (void)addRect:(NSRect)rect;
- (NSRect)frame;
- (NSRect)bounds;
- (void)close;
- (CGPathRef)path;
- (NSBezierPath *)bezierPath;
- (void)translate:(NSPoint)delta;
- (void)finish;

@end
