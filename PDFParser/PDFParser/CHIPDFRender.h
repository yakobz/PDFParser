//
//  CHIPDFRender.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHIPDFRender;

@protocol CHIPDFRenderProtocol <NSObject>

- (NSMutableDictionary *)PDFRender:(CHIPDFRender *)render requestObject:(NSString *)objectName;
- (void)PDFRender:(CHIPDFRender *)render didFinishRenderView:(NSView *)view;
- (void)PDFRender:(CHIPDFRender *)render saveImage:(NSData *)imageData withFrame:(NSRect)frame name:(NSString *)name;
- (void)PDFRender:(CHIPDFRender *)render saveGraphicsWithParams:(NSDictionary *)params svgImageString:(NSString *)svgImageString frame:(NSRect)frame name:(NSString *)name;

@end

@interface CHIPDFRender : NSObject

- (void)reset;
- (void)renderWithPage:(NSDictionary *)page instructions:(NSString *)instructions resources:(NSDictionary *)resources error:(NSError **)error delegate:(id<CHIPDFRenderProtocol>)delegate;

@end
