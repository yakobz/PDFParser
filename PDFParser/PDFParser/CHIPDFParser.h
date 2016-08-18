//
//  CHIPDFParser.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 09.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHIPDFParser;

@protocol CHIPDFParserProtocol <NSObject>

- (void)PDFParser:(CHIPDFParser *)parser didCreateView:(NSView *)view;

@end

@interface CHIPDFParser : NSObject

@property (nonatomic, weak) id <CHIPDFParserProtocol> delegate;

- (BOOL)parseWithURL:(NSURL *)fileURL;

@end
