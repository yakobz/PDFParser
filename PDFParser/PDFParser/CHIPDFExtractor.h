//
//  CHIPDFExtractor.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 15.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHIPDFExtractor : NSObject

+ (CGImageRef)extractImageFromObject:(NSDictionary *)object requestBlock:(NSMutableDictionary *(^)(NSString *name))requestBlock;
+ (CGColorSpaceRef)extractColorSpaceFromObject:(id)colorSpace requestBlock:(NSMutableDictionary *(^)(NSString *name))requestBlock;

@end
