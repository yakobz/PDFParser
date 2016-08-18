//
//  CHIXMLFinalCutCreator.h
//  PDFParser
//
//  Created by Yakov on 8/17/16.
//  Copyright © 2016 Andrew Danileyko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHIXMLFinalCutCreator : NSObject

+ (NSXMLDocument *)createXMLWithContentPath:(NSString *)contentPath;
+ (void)writeXMLDocument:(NSXMLDocument *)xmlDocument toFileWithPath:(NSString *)filePath;

@end
