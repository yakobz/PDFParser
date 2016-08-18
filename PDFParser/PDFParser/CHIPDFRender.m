//
//  CHIPDFRender.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFRender.h"
#import "CHIPDFGraphicsState.h"
#import "CHIPDFRenderView.h"
#import "CHIPDFRef.h"
#import "CHIPDFPath.h"
#import "CHIPDFExtractor.h"
#import "CHIPDFTextState.h"

@interface CHIPDFRender ()

@property (nonatomic, strong) NSMutableArray *_stack;
@property (nonatomic, strong) NSMutableArray *_params;
@property (nonatomic, strong) CHIPDFGraphicsState *_graphicsState;
@property (nonatomic, strong) CHIPDFTextState *_textState;
@property (nonatomic, strong) NSDictionary *_resources;
@property (nonatomic, weak) id<CHIPDFRenderProtocol> _delegate;
@property (nonatomic, strong) NSMutableArray *_objects;

@end

@implementation CHIPDFRender

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self graphicsState];
        [self reset];
    }
    
    return self;
}

- (void)graphicsState {
    self._graphicsState = [[CHIPDFGraphicsState alloc] init];
}

- (void)reset {
    [self._graphicsState reset];
    self._stack = [NSMutableArray array];
    self._params = [NSMutableArray array];
}

- (void)renderWithPage:(NSDictionary *)page instructions:(NSString *)instructions resources:(NSDictionary *)resources error:(NSError **)error delegate:(id<CHIPDFRenderProtocol>)delegate {
    *error = nil;
    NSArray *frameComponents = page[@"entity"][@"MediaBox"];
    NSRect frame = NSMakeRect([frameComponents[0] doubleValue], [frameComponents[1] doubleValue], [frameComponents[2] doubleValue], [frameComponents[3] doubleValue]);
    self._objects = [NSMutableArray array];
    [self._objects addObject:[[CHIPDFRenderView alloc] initWithFrame:frame]];
    self._delegate = delegate;
    self._resources = resources;
    NSString *instructions_ = [instructions stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSArray *components = [instructions_ componentsSeparatedByString:@" "];
    for (NSString *instruction in components) {
        [self postInstruction:instruction];
    }

    [self saveObjects];
}

- (void)postInstruction:(NSString *)instruction {
    if ([instruction isEqualToString:@"b"] || [instruction isEqualToString:@"b*"]) {
#warning Close, fill, stroke path
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"B"] || [instruction isEqualToString:@"B*"]) {
#warning fill, stroke path
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"BDC"]) {
#warning Begin a marked-content sequence with an associated property list, terminated by a balancing EMC
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"BMC"]) {
#warning Begin a marked-content sequence
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"EMC"]) {
#warning End a marked-content sequence
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"BI"]) {
#warning Begin inline image object
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"BT"]) {
        self._textState = [[CHIPDFTextState alloc] init];
#warning Begin text object
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"BX"] || [instruction isEqualToString:@"EX"]) {
        return;
    }

    if ([instruction isEqualToString:@"c"]) {
        [self addCurveToPath];
        return;
    }

    if ([instruction isEqualToString:@"cm"]) {
        [self concatenateMatrix];
        return;
    }

    if ([instruction isEqualToString:@"CS"]) {
#warning Set color space for stroking operations
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"cs"]) {
        [self setColorSpace];
        return;
    }

    if ([instruction isEqualToString:@"d"]) {
#warning Set line dash pattern
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"d0"]) {
#warning Set glyph width in Type 3 font
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"d1"]) {
#warning Set glyph width and bounding box in Type 3 font
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"Do"]) {
        [self printObject];
        return;
    }
    
    if ([instruction isEqualToString:@"DP"]) {
#warning Define marked-content point with property list
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"EI"]) {
#warning End inline image object
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"ET"]) {
#warning End text object
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"f"] || [instruction isEqualToString:@"F"] || [instruction isEqualToString:@"f*"]) {
        [self endPathClose:nil fill:@(YES) stroke:nil];
        return;
    }
    
    if ([instruction isEqualToString:@"G"]) {
#warning Set gray level for stroking operations
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"g"]) {
#warning Set gray level for non stroking operations
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"gs"]) {
#warning Set parameters from graphics state parameter dictionary
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"h"]) {
        [self endPathClose:@(YES) fill:nil stroke:nil];
        return;
    }
    
    if ([instruction isEqualToString:@"i"]) {
#warning Set flatness tolerance
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"ID"]) {
#warning Begin inline image data
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"j"]) {
#warning Set line join style
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"J"]) {
#warning Set line cap style
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"K"]) {
#warning Set CMYK color for stroking operations
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"k"]) {
#warning Set CMYK color for nonstroking operations
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"l"]) {
        [self lineTo];
        return;
    }

    if ([instruction isEqualToString:@"m"]) {
        [self beginSubpath];
        return;
    }
    
    if ([instruction isEqualToString:@"M"]) {
#warning Set miter limit
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"MP"]) {
#warning Define marked-content point
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"n"]) {
        [self endPathClose:@(YES) fill:@(NO) stroke:@(NO)];
        return;
    }

    if ([instruction isEqualToString:@"q"]) {
        [self._stack addObject:[self._graphicsState copy]];
        return;
    }

    if ([instruction isEqualToString:@"Q"]) {
        self._graphicsState = [self._stack lastObject];
        [self._stack removeLastObject];
        return;
    }
    
    if ([instruction isEqualToString:@"re"]) {
        [self addRectToPath];
        return;
    }
    
    if ([instruction isEqualToString:@"RG"]) {
#warning Set RGB color for stroking operations
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"rg"]) {
#warning Set RGB color for nonstroking operations
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"ri"]) {
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"s"]) {
        [self endPathClose:@(YES) fill:nil stroke:@(YES)];
        return;
    }
    
    if ([instruction isEqualToString:@"S"]) {
        [self endPathClose:nil fill:nil stroke:@(YES)];
        return;
    }

    if ([instruction isEqualToString:@"SC"]) {
#warning Set color for stroking operations
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"sc"]) {
        [self setColorFill:YES stroke:NO];
#warning Set color for non stroking operations
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"SCN"]) {
#warning Set color for stroking operations (ICCBased and special color spaces)
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"scn"]) {
#warning Set color for non stroking operations (ICCBased and special color spaces)
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"sh"]) {
#warning Paint area defined by shading pattern
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"T*"]) {
#warning Move to start of next text line
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"Tc"]) {
        NSNumber *textCharacterSpacing = self._params[0];
        self._textState.characterSpacing = [textCharacterSpacing doubleValue];
#warning Set character spacing
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"Td"]) {
#warning Move text position
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"TD"]) {
#warning Move text position and set leading
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"Tf"]) {
        [self setTextFontAndSize];
        return;
    }
    
    if ([instruction isEqualToString:@"Tj"]) {
#warning Show text
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"TJ"]) {
#warning Show text, allowing individual glyph positioning
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"TL"]) {
#warning Set text leading
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"Tm"]) {
#warning Set text matrix and text line matrix
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"Tr"]) {
#warning Set text rendering mode
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"Ts"]) {
#warning Set text rise
        [self resetParams];
        return;
    }
 
    if ([instruction isEqualToString:@"Tw"]) {
#warning Set word spacing
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"Tz"]) {
#warning Set horizontal text scaling
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"v"]) {
#warning Append curved segment to path (initial point replicated)
        [self resetParams];
        return;
    }
    
    if ([instruction isEqualToString:@"w"]) {
#warning Set line width
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"W"] || [instruction isEqualToString:@"W*"]) {
        [self createClipView];
        return;
    }
    
    if ([instruction isEqualToString:@"y"]) {
#warning Append curved segment to path (final point replicated)
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"'"]) {
#warning Move to next line and show text
        [self resetParams];
        return;
    }

    if ([instruction isEqualToString:@"\""]) {
#warning Set word and character spacing, move to next line, and show text
        [self resetParams];
        return;
    }

    [self._params addObject:instruction];
}

- (void)resetParams {
    [self._params removeAllObjects];
}

- (void)concatenateMatrix {
    NSInteger index = self._params.count - 1;
    CGAffineTransform transform = CGAffineTransformMake([self._params[index - 5] doubleValue], [self._params[index - 4] doubleValue], [self._params[index - 3] doubleValue], [self._params[index - 2] doubleValue], [self._params[index - 1] doubleValue], [self._params[index] doubleValue]);
    [self._graphicsState concatenateMatrix:transform];
    [self resetParams];
}

- (void)setColorSpace {
    id object = [[self._params lastObject] stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSDictionary *colorSpaces = self._resources[@"entity"][@"ColorSpace"];
    if ([colorSpaces isKindOfClass:[NSDictionary class]]) {
        id colorSpaceObj = colorSpaces[object];
        CGColorSpaceRef colorSpace = [CHIPDFExtractor extractColorSpaceFromObject:colorSpaceObj requestBlock:^NSMutableDictionary *(NSString *name) {
            return [self requestedObjectWithName:name];
        }];
        self._graphicsState.colorSpace = colorSpace;
    }
    [self resetParams];
}

- (void)setColorFill:(BOOL)fill stroke:(BOOL)stroke {
    NSInteger numberOfComponents = self._params.count;
    CGColorRef color = NULL;
    switch (numberOfComponents) {
        case 1: {
            color = CGColorCreateGenericGray([[self._params lastObject] doubleValue], 1.0);
        } break;
            
        case 3: {
            NSInteger index = self._params.count - 1;
            color = CGColorCreateGenericRGB([self._params[index - 2] doubleValue], [self._params[index - 1] doubleValue], [self._params[index] doubleValue], 1.0);
        } break;

        case 4: {
            NSInteger index = self._params.count - 1;
            color = CGColorCreateGenericCMYK([self._params[index - 3] doubleValue], [self._params[index - 2] doubleValue], [self._params[index - 1] doubleValue], [self._params[index] doubleValue], 1.0);
        } break;
    }
    
    if (color) {
        if (fill) {
            self._graphicsState.colorFill = CGColorRetain(color);
        }
        if (stroke) {
            self._graphicsState.colorFill = CGColorRetain(color);
        }
        CGColorRelease(color);
    }
    
    [self resetParams];
}

- (void)setTextFontAndSize {
    double size = [self._params[self._params.count - 1] doubleValue];
    NSString *fontName = [self._params[0] stringByReplacingOccurrencesOfString:@"/" withString:@""];
    CHIPDFRef *fontRef = self._resources[@"entity"][@"Font"][fontName];
    if (fontRef) {
        NSMutableDictionary *object = [self requestedObjectWithName:fontRef.name];
        NSMutableDictionary *fontDescriptor = [self requestedObjectWithName:[object[@"entity"][@"FontDescriptor"] name]];
        NSMutableDictionary *fontFileDescription = [self requestedObjectWithName:[fontDescriptor[@"entity"][@"FontFile3"] name]];
        NSString *fontName = fontDescriptor[@"entity"][@"FontName"];
        NSData *fontFile = fontFileDescription[@"decodedStream"];
        BOOL success = [fontFile writeToFile:[NSString stringWithFormat:@"/Users/andrewdanileyko/Desktop/%@.ttf", fontName] atomically:YES];
        if (!success) {
            NSLog(@"Font saving error");
        }
//        NSLog(@"%@", object);
//        NSLog(@"%@", fontDescriptor);
//        NSLog(@"%@", fontFile);
    }
    [self resetParams];
}

- (CHIPDFPath *)path {
    id object = [self._objects lastObject];
    CHIPDFPath *path = nil;
    if ([object isKindOfClass:[CHIPDFPath class]] && ![object finished]) {
        path = object;
    } else {
        path = [[CHIPDFPath alloc] init];
        [self._objects addObject:path];
    }
    
    return path;
}

- (void)addRectToPath {
    CHIPDFPath *path = [self path];
    NSInteger index = self._params.count - 1;
    NSRect rect = NSMakeRect([self._params[index - 3] doubleValue], [self._params[index - 2] doubleValue], [self._params[index - 1] doubleValue], [self._params[index] doubleValue]);
    [path addRect:rect];
    [self resetParams];
}

- (void)beginSubpath {
    NSInteger index = self._params.count - 1;
    NSPoint point = NSMakePoint([self._params[index - 1] doubleValue], [self._params[index] doubleValue]);
    CHIPDFPath *path = [self path];
    [path moveToPoint:point];
    [self resetParams];
}

- (void)lineTo {
    NSInteger index = self._params.count - 1;
    NSPoint point = NSMakePoint([self._params[index - 1] doubleValue], [self._params[index] doubleValue]);
    CHIPDFPath *path = [self path];
    [path lineToPoint:point];
    [self resetParams];
}

- (void)addCurveToPath {
    NSInteger index = self._params.count - 1;
    NSPoint point1 = NSMakePoint([self._params[index - 5] doubleValue], [self._params[index - 4] doubleValue]);
    NSPoint point2 = NSMakePoint([self._params[index - 3] doubleValue], [self._params[index - 2] doubleValue]);
    NSPoint point3 = NSMakePoint([self._params[index - 1] doubleValue], [self._params[index] doubleValue]);
    CHIPDFPath *path = [self path];
    [path addCurvePoint1:point1 point2:point2 point3:point3];
    [self resetParams];
}

- (void)createClipView {
    id object = [self._objects lastObject];
    if ([object isKindOfClass:[CHIPDFPath class]]) {
        CHIPDFRenderView *clipView = [[CHIPDFRenderView alloc] init];
        clipView.clipPath = object;
        [self._objects removeLastObject];
        [self._objects addObject:clipView];
    }
    [self resetParams];
}

- (void)endPathClose:(NSNumber *)close fill:(NSNumber *)fill stroke:(NSNumber *)stroke {
    id object = [self._objects lastObject];
    if ([object isKindOfClass:[CHIPDFPath class]]) {
        if (close) {
            [object close];
        }
        if (fill) {
            [object setFill:[fill boolValue]];
            [object setFinished:YES];
            [object finish];
        }
        if (stroke) {
            [object setStroke:[stroke boolValue]];
            [object setFinished:YES];
            [object finish];
        }
        
        [object setGraphicsState:[self._graphicsState copy]];
    }
    [self resetParams];
}

- (void)printObject {
    NSString *objectName = [self._params[0] stringByReplacingOccurrencesOfString:@"/" withString:@""];
    CHIPDFRef *objRef = self._resources[@"entity"][@"XObject"][objectName];
    NSMutableDictionary *object = [self requestedObjectWithName:objRef.name];
    
    CHIPDFRef *sMask = object[@"entity"][@"SMask"];
    NSMutableDictionary *maskObject;
    if (sMask) {
        
    }
    
    if (object && [object[@"entity"][@"Subtype"] isEqualToString:@"Image"]) {
        [self saveImageWithObject:object name:objectName];
    }
    
    [self resetParams];
}

- (NSMutableDictionary *)requestedObjectWithName:(NSString *)name {
    if ([self._delegate respondsToSelector:@selector(PDFRender:requestObject:)]) {
        return [self._delegate PDFRender:self requestObject:name];
    }
    return nil;
}

#pragma mark - Saving Objects

- (void)saveObjects {
    int i = 0;
    for (id object in self._objects) {
        if ([object isKindOfClass:[CHIPDFPath class]]) {
            [self saveGraphicsWithObject:object number:i++];
        }
    }
}

#pragma mark - Saving image

- (void)saveImageWithObject:(NSDictionary *)object name:(NSString *)name {
    CGImageRef cgImage = [CHIPDFExtractor extractImageFromObject:object requestBlock:^NSMutableDictionary *(NSString *name) {
        return [self requestedObjectWithName:name];
    }];
    
    if (cgImage) {
        NSData *imageData = [self imageData:cgImage];
        NSRect imageFrame = [self imageFrameWithObject:object];
        
        if ([self._delegate respondsToSelector:@selector(PDFRender:saveImage:withFrame:name:)]) {
            [self._delegate PDFRender:self saveImage:imageData withFrame:imageFrame name:name];
        }
    }
}

//- (NSData *)imageData:(CGImageRef)cgImage {
//    CHIPDFRenderView *renderView = [self._objects lastObject];
//    
//    CGImageRef cgResultImage = cgImage;
//    
//    if ([renderView isKindOfClass:[CHIPDFRenderView class]]) {
//        NSBezierPath *path = renderView.clipPath.bezierPath;
//        CGPathRef cgpath = renderView.clipPath.path;
//        
//        path = [[NSBezierPath alloc] init];
//        [path moveToPoint:NSMakePoint(30.65685, 0.3431458)];
//        [path curveToPoint:NSMakePoint(33.78105, 3.46734) controlPoint1:NSMakePoint(33.78105, 8.53266) controlPoint2:NSMakePoint(30.65685, 11.65685)];
//        [path curveToPoint:NSMakePoint(27.53266, 14.78105) controlPoint1:NSMakePoint(22.46734, 14.78105) controlPoint2:NSMakePoint(19.34315, 11.65685)];
//        [path curveToPoint:NSMakePoint(16.21895, 8.53266) controlPoint1:NSMakePoint(16.21895, 3.46734) controlPoint2:NSMakePoint(19.34315, 0.3431458)];
//        [path curveToPoint:NSMakePoint(22.46734, -2.781049) controlPoint1:NSMakePoint(27.53266, -2.781049) controlPoint2:NSMakePoint(30.65685, 0.3431458)];
//        
//        NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage))];
//        
//        CGContextRef bitmapContext = CGBitmapContextCreate(NULL, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, 0, [NSColorSpace genericRGBColorSpace].CGColorSpace, kCGImageAlphaPremultipliedLast);
//        
//        [NSGraphicsContext saveGraphicsState];
//        [path addClip];
//        [image drawInRect:CGPathGetBoundingBox(cgpath) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//        
//        cgResultImage = CGBitmapContextCreateImage(bitmapContext);
//        CGContextRelease(bitmapContext);
//        [NSGraphicsContext restoreGraphicsState];
//    }
//    
//    NSImage *image = [[NSImage alloc] initWithCGImage:cgResultImage size:NSMakeSize(CGImageGetWidth(cgResultImage), CGImageGetHeight(cgResultImage))];
//    [image lockFocus];
//    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
//    [image unlockFocus];
//    
//    NSData *imageData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
//    return imageData;
//}

- (NSData *)imageData:(CGImageRef)cgImage {
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage))];
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    NSData *imageData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
    return imageData;
}

- (NSRect)imageFrameWithObject:(NSDictionary *)object {
    CGFloat width = [object[@"entity"][@"Width"] floatValue];
    CGFloat height = [object[@"entity"][@"Height"] floatValue];
    CGFloat x = self._graphicsState.ctm.tx;
    CGFloat y = self._graphicsState.ctm.ty;
    
    return CGRectIntegral(NSMakeRect(x, y, width, height));
}

#pragma mark - Saving Graphics

- (void)saveGraphicsWithObject:(CHIPDFPath *)pdfPath number:(int)number {
    NSMutableDictionary *graphicsParams = [NSMutableDictionary dictionaryWithDictionary:[self colorParamsForPdfPath:pdfPath]];
    
    graphicsParams[@"lineWidth"] = @(pdfPath.graphicsState.lineWidth);
    graphicsParams[@"path"] = [self convertParamsForPdfPath:pdfPath];
    
    if ([self._delegate respondsToSelector:@selector(PDFRender:saveGraphicsWithParams:svgImageString:frame:name:)]) {
        NSString *name = [NSString stringWithFormat:@"graphics%i", number];
        [self._delegate PDFRender:self saveGraphicsWithParams:graphicsParams svgImageString:pdfPath.svgPath frame:pdfPath.frame name:name];
    }
}

- (NSArray *)convertParamsForPdfPath:(CHIPDFPath *)pdfPath {
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSDictionary *param in pdfPath.pathArray) {
        NSMutableDictionary *dictionaryValue = [NSMutableDictionary dictionary];
        
        for (NSString *paramKey in param) {
            NSString *value;
            
            if ([paramKey isEqualToString:@"addRect"]) {
                NSRect frame = NSRectFromString(param[paramKey]);
                frame.origin = NSMakePoint(CGRectGetMinX(frame) - CGRectGetMinX(pdfPath.frame), CGRectGetMinY(frame) - CGRectGetMinY(pdfPath.frame));
                value = NSStringFromRect(frame);
            } else {
                NSPoint origin = NSPointFromString(param[paramKey]);
                origin = NSMakePoint(origin.x - CGRectGetMinX(pdfPath.frame), origin.y - CGRectGetMinY(pdfPath.frame));
                value = NSStringFromPoint(origin);
            }
            
            dictionaryValue[paramKey] = value;
        }
        
        [result addObject:dictionaryValue];
    }
    
    return result;
}

- (NSDictionary *)colorParamsForPdfPath:(CHIPDFPath *)pdfPath {
    NSMutableDictionary *colorParams = [NSMutableDictionary dictionary];

    if (pdfPath.fill && pdfPath.graphicsState.colorFill != NULL) {
        NSColor *fillColor = [NSColor colorWithCGColor:pdfPath.graphicsState.colorFill];
        colorParams[@"fillColor"] = [NSKeyedArchiver archivedDataWithRootObject:fillColor];
    }
    
    if (pdfPath.stroke && pdfPath.graphicsState.colorStroke != NULL) {
        NSColor *strokeColor = [NSColor colorWithCGColor:pdfPath.graphicsState.colorStroke];
        colorParams[@"strokeColor"] = [NSKeyedArchiver archivedDataWithRootObject:strokeColor];
    }
    
    CFStringRef colorSpaceName = CGColorSpaceCopyName(pdfPath.graphicsState.colorSpace);
    NSString *colorSpace = (__bridge NSString *)colorSpaceName;
    
    if (colorSpace) {
        colorParams[@"colorSpaceName"] = [NSKeyedArchiver archivedDataWithRootObject:colorSpace];
    }
    
    return colorParams;
}

@end
