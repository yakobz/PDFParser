//
//  CHIPDFParser.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 09.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#include <stdio.h>
#import "CHIPDFParser.h"
#import "CHIPDFParserReadFunctions.h"
#import "NSData+Compression.h"
#import "CHIPDFExtractor.h"
#import "CHIPDFRef.h"
#import "CHIPDFRender.h"

@interface CHIPDFParser () <CHIPDFRenderProtocol>

@property (nonatomic, strong) NSArray *_xref;
@property (nonatomic, strong) NSDictionary *_trailer;
@property (nonatomic, strong) NSMutableDictionary *_objects;
@property (nonatomic, strong) NSURL *_folderUrl;

@end

@implementation CHIPDFParser

- (BOOL)parseWithURL:(NSURL *)fileURL {
    if ([fileURL.path isEqualToString:@"/Users/Yakov/Downloads/15.08.2016_16-16-21.605/15.08.2016_16-16-21.605/com.skype.skype/0/NSThemeFrame_0x7f9d6df2f400/NSTitlebarContainerView_0x7f9d6df2efc0/NSTitlebarView_0x7f9d6df386c0/NSView_0x7f9d6df69cf0/NSTitlebarAccessoryClipView_0x7f9d6df430d0/NSView_0x7f9d6ddbc1b0/NSStackView_0x7f9d6dce0470/NSView_0x7f9d6ddbba20/SmallAccountView_0x7f9d6df14600/NSView_0x7f9d6dc81360/RoundToolbarImageView_0x7f9d6de3eac0/object.pdf"]) {
        
    }
    
    const char *filename = [[fileURL path] cStringUsingEncoding:NSUTF8StringEncoding];
    FILE *file = fopen(filename, "r");
    
    self._xref = [CHIPDFParserReadFunctions readxRefInFile:file];
    if (!self._xref) {
        NSLog(@"PDF parse error: startxref notfound");
        fclose(file);
    } else {
        self._folderUrl = [fileURL URLByDeletingLastPathComponent];
        
        self._trailer = [CHIPDFParserReadFunctions readTrailerFile:file];
        [self readObjectsFromFile:file];
        
        NSMutableDictionary *rootObject = [self objectWithName:[self._trailer[@"Root"] name]];
        if ([rootObject[@"entity"][@"Type"] isEqualToString:@"Catalog"]) {
            [self parseCatalog:rootObject];
        }
        
        fclose(file);
    }
    
    return YES;
}

- (void)parseCatalog:(NSMutableDictionary *)catalog {
    NSMutableDictionary *catalogPages = [self objectWithName:[catalog[@"entity"][@"Pages"] name]];
    NSDictionary *entity = catalogPages[@"entity"];
    for (CHIPDFRef *ref in entity[@"Kids"]) {
        NSDictionary *page = [self objectWithName:ref.name];
        [self parsePage:page];
    }
}

- (void)parsePage:(NSDictionary *)page {
    NSDictionary *contents = [self objectWithName:[page[@"entity"][@"Contents"] name]];
    NSDictionary *resources = [self objectWithName:[page[@"entity"][@"Resources"] name]];
    
    NSData *contentsStream = contents[@"decodedStream"];
    if (contentsStream) {
        NSString *instuctions = [[NSString alloc] initWithData:contentsStream encoding:NSASCIIStringEncoding];
        CHIPDFRender *render = [[CHIPDFRender alloc] init];
        NSError *error;
        [render renderWithPage:page instructions:instuctions resources:resources error:&error delegate:(id)self];
    }
}

- (void)readObjectsFromFile:(FILE *)file {
    self._objects = [NSMutableDictionary dictionary];
    for (NSString *offsetString in self._xref) {
        NSInteger offset = [offsetString integerValue];
        NSDictionary *rawObject = [self readObjectFromFile:file offset:offset];
        self._objects[rawObject[@"name"]] = rawObject;
    }
    
    for (NSMutableDictionary *object in [self._objects allValues]) {
        NSMutableDictionary *entity = object[@"entity"];
        if ([entity isKindOfClass:[NSDictionary class]] && [entity[@"Filter"] isEqualToString:@"FlateDecode"]) {
            NSData *stream = object[@"stream"];
            if (stream) {
                NSData *decodedStream = [stream zlibInflate];
                object[@"decodedStream"] = decodedStream;
                [object removeObjectForKey:@"stream"];
            }
        }
    }
}

- (NSMutableDictionary *)objectWithName:(NSString *)name {
    return self._objects[name];
}

- (NSMutableDictionary *)readObjectFromFile:(FILE *)file offset:(NSInteger)offset {
    fseek(file, offset, SEEK_SET);
    NSString *line;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    do {
        line = [CHIPDFParserReadFunctions readNextLineAsNSStringFromFile:file];
        if (![line isEqualToString:@"endobj"]) {
            if ([line isEqualToString:@"stream"]) {
                NSData *data = [CHIPDFParserReadFunctions readStream:file];
                result[@"stream"] = data;
            } else {
                NSArray *components = [line componentsSeparatedByString:@" "];
                if (components.count == 3 && [components[2] isEqualToString:@"obj"]) {
                    result[@"name"] = [NSString stringWithFormat:@"%@ %@", components[0], components[1]];
                    id nextEntity = [CHIPDFParserReadFunctions readNextEntityFromFIle:file];
                    result[@"entity"] = nextEntity;
                }
            }
        } else {
            break;
        }
    } while(YES);
    
    return result;
}

#pragma mark - CHIPDFRender Protocol

- (NSMutableDictionary *)PDFRender:(CHIPDFRender *)render requestObject:(NSString *)objectName {
    return [self objectWithName:objectName];
}

- (void)PDFRender:(CHIPDFRender *)render didFinishRenderView:(NSView *)view {
    if ([self.delegate respondsToSelector:@selector(PDFParser:didCreateView:)]) {
        [self.delegate PDFParser:self didCreateView:view];
    }
}

- (void)PDFRender:(CHIPDFRender *)render saveImage:(NSData *)imageData withFrame:(NSRect)frame name:(NSString *)name {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *folderUrl = [self._folderUrl URLByAppendingPathComponent:name];
    
    if ([fileManager fileExistsAtPath:folderUrl.path] == NO) {
        [fileManager createDirectoryAtPath:folderUrl.path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [imageData writeToURL:[folderUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]] atomically:NO];

    NSDictionary *infoDictionary = [[NSDictionary alloc] initWithContentsOfURL:[self._folderUrl URLByAppendingPathComponent:@"info.plist"]];
    NSString *frameString = infoDictionary[@"windowFrame"];
    NSRect imageFrame = NSRectFromString(frameString);
    imageFrame.origin.x += CGRectGetMinX(frame);
    imageFrame.origin.y += CGRectGetMinY(frame);
    imageFrame.size = NSMakeSize(CGRectGetWidth(frame), CGRectGetHeight(frame));

    NSDictionary *imageParams = @{@"frame" : NSStringFromRect(imageFrame)};
    [imageParams writeToURL:[folderUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", name]] atomically:YES];
}

- (void)PDFRender:(CHIPDFRender *)render saveGraphicsWithParams:(NSDictionary *)params svgImageString:(NSString *)svgImageString frame:(NSRect)frame name:(NSString *)name {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *folderUrl = [self._folderUrl URLByAppendingPathComponent:name];
    
    if ([fileManager fileExistsAtPath:folderUrl.path] == NO) {
        [fileManager createDirectoryAtPath:folderUrl.path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDictionary *infoDictionary = [[NSDictionary alloc] initWithContentsOfURL:[self._folderUrl URLByAppendingPathComponent:@"info.plist"]];
    NSString *frameString = infoDictionary[@"windowFrame"];
    NSRect graphicsFrame = NSRectFromString(frameString);
    graphicsFrame.origin.x += CGRectGetMinX(frame);
    graphicsFrame.origin.y += CGRectGetMinY(frame);
    graphicsFrame.size = NSMakeSize(CGRectGetWidth(frame), CGRectGetHeight(frame));
    
    NSMutableDictionary *graphicsParams = [NSMutableDictionary dictionaryWithDictionary:params];
    graphicsParams[@"frame"] = NSStringFromRect(graphicsFrame);
    [graphicsParams writeToURL:[folderUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", name]] atomically:YES];
    
    NSData *data = [NSData dataWithBytes:svgImageString.UTF8String length:svgImageString.length];
    [data writeToFile:[folderUrl.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.svg", name]] atomically:YES];
}

@end
