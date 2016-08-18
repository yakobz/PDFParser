//
//  CHIPDFParserReadFunctions.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 13.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHIPDFParserReadFunctions : NSObject

+ (id)readNextEntityFromFIle:(FILE *)file;
+ (NSString *)readString:(FILE *)file openBrace:(char)openBrace closeBrace:(char)closeBrace;
+ (NSNumber *)readNumber:(FILE *)file;
+ (NSDictionary *)readDictionary:(FILE *)file;
+ (NSArray *)readArray:(FILE *)file;
+ (NSData *)readStream:(FILE *)file;
+ (NSArray *)readxRefInFile:(FILE *)file;
+ (NSDictionary *)readTrailerFile:(FILE *)file;
+ (NSString *)readNextLineAsNSStringFromFile:(FILE *)file;
+ (NSString *)readPrevLineAsNSStringFromFile:(FILE *)file;

@end
