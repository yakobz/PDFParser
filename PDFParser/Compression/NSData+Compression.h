//
//  NSData+Compression.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 14.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/NSData.h>

/*! Adds compression and decompression messages to NSData.
 * Methods extracted from source given at
 * http://www.cocoadev.com/index.pl?NSDataCategory
 */
@interface NSData (Compression)

#pragma mark -
#pragma mark Zlib Compression routines
/*! Returns a data object containing a Zlib decompressed copy of the receivers contents.
 */
- (NSData *) zlibInflate;
/*! Returns a data object containing a Zlib compressed copy of the receivers contents.
 */
- (NSData *) zlibDeflate;

#pragma mark -
#pragma mark Gzip Compression routines
/*! Returns a data object containing a Gzip decompressed copy of the receivers contents.
 */
- (NSData *) gzipInflate;
/*! Returns a data object containing a Gzip compressed copy of the receivers contents.
 */
- (NSData *) gzipDeflate;

@end
