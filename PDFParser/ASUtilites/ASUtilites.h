//
//  ASUtilites.h
//  TokensApp
//
//  Created by  IOS DEV ad-sys on 30.10.14.
//  Copyright (c) 2014  IOS DEV ad-sys. All rights reserved.
//

#define ls(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

@interface ASUtilites : NSObject

+ (NSString *)GUID;
+ (void)clearCache;
+ (BOOL)validateEmail:(NSString *)email;
+ (BOOL)isSupportedImageExtention:(NSString *)ext;
+ (BOOL)isSupportedVideoExtention:(NSString *)ext;
+ (BOOL)isVideoExists;
+ (BOOL)applicationIsRunning;
+ (void)closeAllWindows;

@end