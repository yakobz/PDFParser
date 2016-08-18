//
//  CHIPDFPath.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 23.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFPath.h"
#import "CHIPDFGraphicsState.h"

@interface CHIPDFPath ()

@property (nonatomic, strong) NSBezierPath *_bezierPath;

@property (nonatomic) CGMutablePathRef _path;
@property (nonatomic) NSPoint _previousPoint;

@end

void pathApplierFunction(void * __nullable info, const CGPathElement *  element);

@implementation CHIPDFPath

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.pathArray = [NSMutableArray array];
        self._bezierPath = [NSBezierPath bezierPath];
        
        self._path = CGPathCreateMutable();
        self.svgPath = @"";
        self._previousPoint = NSMakePoint(0, 0);
        self.stroke = NO;
        self.fill = NO;
        self.finished = NO;
    }
    
    return self;
}

- (CGPathRef)path {
    return self._path;
}

- (NSBezierPath *)bezierPath {
    return self._bezierPath;
}

- (void)moveToPoint:(NSPoint)point {
//    if (CGPathContainsPoint(self._path, NULL, point, true) == NO) {
//        return;
//    }
    
    CGPathMoveToPoint(self._path, NULL, point.x, point.y);
    [self._bezierPath moveToPoint:point];

    [self.pathArray addObject:@{@"moveToPoint" : NSStringFromPoint(point)}];
    
    NSPoint transformPoint = NSMakePoint(point.x - self._previousPoint.x, point.y - self._previousPoint.y);
    self._previousPoint = point;
    
    self.svgPath = [self.svgPath stringByAppendingString:[NSString stringWithFormat:@"m %.2f %.2f ", transformPoint.x, transformPoint.y]];
}

- (void)lineToPoint:(NSPoint)point {
//    if (CGPathContainsPoint(self._path, NULL, point, true) == NO) {
//        return;
//    }
    
    CGPathAddLineToPoint(self._path, NULL, point.x, point.y);
    [self._bezierPath lineToPoint:point];
    
    [self.pathArray addObject:@{@"lineToPoint" : NSStringFromPoint(point)}];

    NSPoint transformPoint = NSMakePoint(point.x - self._previousPoint.x, point.y - self._previousPoint.y);
    self._previousPoint = point;
    
    self.svgPath = [self.svgPath stringByAppendingString:[NSString stringWithFormat:@"l %.2f %.2f ", transformPoint.x, transformPoint.y]];
}

- (void)addCurvePoint1:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3 {
//    if (CGPathContainsPoint(self._path, NULL, point1, true) == NO) {
//        return;
//    }
    
    CGPathAddCurveToPoint(self._path, NULL, point1.x, point1.y, point2.x, point2.y, point3.x, point3.y);
    [self._bezierPath curveToPoint:point1 controlPoint1:point2 controlPoint2:point3];
    
    [self.pathArray addObject:@{@"addCurvePoint1" : NSStringFromPoint(point1),
                                @"point2" : NSStringFromPoint(point2),
                                @"point3" : NSStringFromPoint(point3)}];
    
    NSPoint transformPoint1 = NSMakePoint(point1.x - self._previousPoint.x, point1.y - self._previousPoint.y);
    NSPoint transformPoint2 = NSMakePoint(point2.x - self._previousPoint.x, point2.y - self._previousPoint.y);
    NSPoint transformPoint3 = NSMakePoint(point3.x - self._previousPoint.x, point3.y - self._previousPoint.y);
    self._previousPoint = point3;
    
    self.svgPath = [self.svgPath stringByAppendingString:[NSString stringWithFormat:@"c %.2f %.2f %.2f %.2f %.2f %.2f ", transformPoint1.x, transformPoint1.y, transformPoint2.x, transformPoint2.y, transformPoint3.x, transformPoint3.y]];
}

- (void)addRect:(NSRect)rect {
    if (self._path) {
        CGPathAddRect(self._path, NULL, rect);
        [self.pathArray addObject:@{@"addRect" : NSStringFromRect(rect)}];
    }
}

- (void)close {
    CGPathCloseSubpath(self._path);
}

- (NSRect)frame {
    if (self._path && !CGPathIsEmpty(self._path)) {
        return CGPathGetBoundingBox(self._path);
    }
    
    return NSZeroRect;
}

- (NSRect)bounds {
    if (self._path) {
        NSRect frame = self.frame;
        return NSMakeRect(0, 0, frame.size.width, frame.size.height);
    }
    
    return NSZeroRect;
}

- (void)finish {
    NSString *header = [NSString stringWithFormat:@"<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"%.2f %.2f %.2f %.2f\">\n<path d=\"", CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)];
    self.svgPath = [header stringByAppendingString:self.svgPath];
    
    if (self.fill && self.graphicsState.colorFill != NULL) {
        NSColor *fillColor = [NSColor colorWithCGColor:self.graphicsState.colorFill];
        fillColor = [fillColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
        NSString *colorString = [NSString stringWithFormat:@"\" fill=\"#%02X%02X%02X\"", (int)(fillColor.redComponent * 0xFF), (int)(fillColor.greenComponent * 0xFF), (int)(fillColor.blueComponent * 0xFF)];
        self.svgPath = [self.svgPath stringByAppendingString:colorString];
    }
    
    if (self.stroke && self.graphicsState.colorStroke != NULL) {
        NSColor *strokeColor = [NSColor colorWithCGColor:self.graphicsState.colorStroke];
        strokeColor = [strokeColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
        NSString *colorString = [NSString stringWithFormat:@"\" stroke=\"#%02X%02X%02X\"", (int)(strokeColor.redComponent * 0xFF), (int)(strokeColor.greenComponent * 0xFF), (int)(strokeColor.blueComponent * 0xFF)];
        self.svgPath = [self.svgPath stringByAppendingString:colorString];
    }
    
    self.svgPath = [self.svgPath stringByAppendingString:[NSString stringWithFormat:@"/>\n</svg>"]];
}

- (void)dealloc {
    CGPathRelease(self._path);
}

void pathApplierFunction(void * __nullable info, const CGPathElement *  element) {
    NSLog(@"%@", info);
}

@end
