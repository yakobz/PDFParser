//
//  CHIPDFExtractor.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 15.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFExtractor.h"
#import "CHIPDFRef.h"
#import "ASUtilites.h"

CGFloat *decodeValuesFromImageDictionary(CGColorSpaceRef cgColorSpace, NSInteger bitsPerComponent);

@implementation CHIPDFExtractor

CGFloat *decodeValuesFromImageDictionary(CGColorSpaceRef cgColorSpace, NSInteger bitsPerComponent) {
    CGFloat *decodeValues = NULL;
    
    size_t n;
    switch (CGColorSpaceGetModel(cgColorSpace)) {
        case kCGColorSpaceModelMonochrome:
            decodeValues = malloc(sizeof(CGFloat) * 2);
            decodeValues[0] = 0.0;
            decodeValues[1] = 1.0;
            break;
        case kCGColorSpaceModelRGB:
            decodeValues = malloc(sizeof(CGFloat) * 6);
            for (int i = 0; i < 6; i++) {
                decodeValues[i] = i % 2 == 0 ? 0 : 1;
            }
            break;
        case kCGColorSpaceModelCMYK:
            decodeValues = malloc(sizeof(CGFloat) * 8);
            for (int i = 0; i < 8; i++) {
                decodeValues[i] = i % 2 == 0 ? 0.0 : 1.0;
            }
            break;
        case kCGColorSpaceModelLab:
            // ????
            break;
        case kCGColorSpaceModelDeviceN:
            n = CGColorSpaceGetNumberOfComponents(cgColorSpace) * 2;
            decodeValues = malloc(sizeof(CGFloat) * (n * 2));
            for (int i = 0; i < n; i++) {
                decodeValues[i] = i % 2 == 0 ? 0.0 : 1.0;
            }
            break;
        case kCGColorSpaceModelIndexed:
            decodeValues = malloc(sizeof(CGFloat) * 2);
            decodeValues[0] = 0.0;
            decodeValues[1] = pow(2.0, (double)bitsPerComponent) - 1;
            break;
        default:
            break;
    }
    
    return decodeValues;
}

+ (CFStringRef)colorSpaceNameFromPDFColorSpaceName:(NSString *)name {
    if ([name isEqualToString:@"DeviceRGB"]) {
        return kCGColorSpaceGenericRGB;
    }
    
    if ([name isEqualToString:@"DeviceCMYK"]) {
        return kCGColorSpaceGenericCMYK;
    }
    
    return kCGColorSpaceGenericGray;
}

+ (CGImageRef)extractImageFromObject:(NSDictionary *)object requestBlock:(NSMutableDictionary *(^)(NSString *name))requestBlock {
    CGImageRef cgImage = [self extractCGImageFromObject:object requestBlock:requestBlock];
    if (cgImage) {
        if (object[@"entity"][@"SMask"]) {
            NSMutableDictionary *maskObject = requestBlock([object[@"entity"][@"SMask"] name]);
            CGImageRef cgMask = [self extractCGImageFromObject:maskObject requestBlock:requestBlock];
            if (cgMask) {
                size_t width = CGImageGetWidth(cgMask);
                size_t height = CGImageGetHeight(cgMask);
                size_t bpc = CGImageGetBitsPerComponent(cgImage);
                size_t bpr = CGImageGetBytesPerRow(cgImage);
                CGImageRef maskedImageRef = CGImageCreateWithMask(cgImage, cgMask);
                
                CGContextRef context = CGBitmapContextCreate(NULL, width, height, bpc, bpr + width, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
                CGContextDrawImage(context, CGRectMake(0, 0, width, height), maskedImageRef);
                CGImageRef result = CGBitmapContextCreateImage(context);
                CGContextRelease(context);
                
//                NSString *randomName = [ASUtilites GUID];
//                CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Users/andrewdanileyko/Desktop/%@.png", randomName]];
//                CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
//                CGImageDestinationAddImage(destination, result, NULL);
//                CGImageDestinationFinalize(destination);
                return result;
            }
        }
        return cgImage;
    }
    return nil;
}

+ (CGColorSpaceRef)extractColorSpaceFromObject:(id)colorSpace requestBlock:(NSMutableDictionary *(^)(NSString *name))requestBlock {
    CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
    
    if ([colorSpace isKindOfClass:[CHIPDFRef class]]) {
        NSMutableDictionary *colorSpaceObject = requestBlock([colorSpace name]);
        if ([colorSpaceObject[@"entity"] isKindOfClass:[NSArray class]] && [colorSpaceObject[@"entity"][0] isEqualToString:@"ICCBased"]) {
            if ([colorSpaceObject[@"entity"][1] isKindOfClass:[CHIPDFRef class]]) {
                NSMutableDictionary *ICCObject = requestBlock([colorSpaceObject[@"entity"][1] name]);
                NSData *profile = ICCObject[@"decodedStream"];
                cgColorSpace = CGColorSpaceCreateWithICCProfile((CFDataRef)profile);
                if (!cgColorSpace && ICCObject[@"Alternate"]) {
                    // set Alternate colorspace
                }
            } else {
                // entity is not a reference
            }
        } else {
            // entity is not array or not ICCBased
        }
    } else {
        if ([colorSpace isKindOfClass:[NSString class]]) {
            NSString *colorSpaceName = colorSpace;
            cgColorSpace = CGColorSpaceCreateWithName([self colorSpaceNameFromPDFColorSpaceName:colorSpaceName]);
        }
    }
    
    return cgColorSpace;
}

+ (CGImageRef)extractCGImageFromObject:(NSDictionary *)object requestBlock:(NSMutableDictionary *(^)(NSString *name))requestBlock {
    NSDictionary *entity = object[@"entity"];
    size_t width = [entity[@"Width"] intValue];
    size_t height = [entity[@"Height"] intValue];
    size_t bpc = [entity[@"BitsPerComponent"] intValue];
    CGColorSpaceRef cgColorSpace = [self extractColorSpaceFromObject:entity[@"ColorSpace"] requestBlock:requestBlock];
    
    size_t spp = CGColorSpaceGetNumberOfComponents(cgColorSpace);
    size_t rowBytes = bpc * spp * width / 8;
    CGPDFBoolean interpolation = [entity[@"Interpolate"] intValue];
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGFloat *decodeValues = decodeValuesFromImageDictionary(cgColorSpace, bpc);
    
    NSData *buffer = object[@"decodedStream"];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)buffer);
    
    CGImageRef cgImage = CGImageCreate(width, height, bpc, bpc * spp, rowBytes, cgColorSpace, 0, dataProvider, decodeValues, interpolation, renderingIntent);
    CGDataProviderRelease(dataProvider);
    
    CGColorSpaceRelease(cgColorSpace);
    return cgImage;
}

@end
