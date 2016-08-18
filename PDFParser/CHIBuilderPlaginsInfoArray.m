//
//  CHIBuilderPlaginsInfoArray.m
//  PDFParser
//
//  Created by Yakov on 8/17/16.
//  Copyright © 2016 Andrew Danileyko. All rights reserved.
//

#import "CHIBuilderPlaginsInfoArray.h"

static NSMutableArray *plaginsArray;
static NSMutableArray *namesOfUsedGrabInfoPlists;
static NSString * mainFolderPath;

@implementation CHIBuilderPlaginsInfoArray

+ (NSArray *)plaginsArrayForContentWithPath:(NSString *)contentPath {
    plaginsArray = [NSMutableArray array];
    namesOfUsedGrabInfoPlists = [NSMutableArray array];
    mainFolderPath = contentPath;
    
    NSArray *folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contentPath error:nil];
    
    for (NSString *folderItem in folderContent) {
        NSString *itemPath = [contentPath stringByAppendingPathComponent:folderItem];
        
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                
                dictionary[@"name"] = folderItem;
                dictionary[@"paths"] = @[itemPath];
                
                NSMutableArray *subPlagins = [NSMutableArray array];
                [self addPlaginInfoToArray:subPlagins forPath:itemPath];
                dictionary[@"subPlagins"] = subPlagins;
                
                [plaginsArray addObject:dictionary];
            }
        }
    }

    return plaginsArray;
}

+ (void)addPlaginInfoToArray:(NSMutableArray *)array forPath:(NSString *)path {
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    
    BOOL isDirectory;
    if ([defaultFileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            NSString *grabInfoPlistPath = [self grabInfoPlistPathFromFolderWithPath:path];
            
            if (grabInfoPlistPath) {
                [self addPlaginInfoToArray:array forPath:grabInfoPlistPath];
            } else {
                for (NSString *folderPath in [self subFoldersPathsFromFolderWithPath:path]) {
                    [self addPlaginInfoToArray:array forPath:folderPath];
                }
            }
        } else if ([path.lastPathComponent isEqualToString:@"grabInfo.plist"]) {
            NSString *plaginPathWithName = [path stringByDeletingLastPathComponent];
            
            if ([self plaginWithNameExists:plaginPathWithName.lastPathComponent] == NO) {
                [namesOfUsedGrabInfoPlists addObject:plaginPathWithName.lastPathComponent];
                [self addNewPlaginWithPath:plaginPathWithName toArray:array];
            }
        }
    }

}

+ (BOOL)plaginWithNameExists:(NSString *)plaginName {
    for (NSString *usedPlaginName in namesOfUsedGrabInfoPlists) {
        if ([plaginName isEqualToString:usedPlaginName]) {
            return YES;
        }
    }
    
    return NO;
}

+ (void)addNewPlaginWithPath:(NSString *)plaginPath toArray:(NSMutableArray *)array {
    NSMutableDictionary *plaginInfo = [NSMutableDictionary dictionary];
    
    plaginInfo[@"name"] = plaginPath.lastPathComponent;
    
    NSMutableArray *pathsArray = [NSMutableArray array];
    [self paths:pathsArray toPlaginWithName:plaginPath.lastPathComponent fromFolder:mainFolderPath];
    plaginInfo[@"paths"] = pathsArray;
    
    NSMutableArray *subFoldersForAllFolders = [NSMutableArray array];
    for (NSString *path in pathsArray) {
        [subFoldersForAllFolders addObjectsFromArray:[self subFoldersPathsFromFolderWithPath:path]];
    }
    
    NSMutableArray *subPlArray = [NSMutableArray array];
    for (NSString *folderPaths in [self subFoldersPathsFromFolderWithPath:plaginPath]) {
        [self addPlaginInfoToArray:subPlArray forPath:folderPaths];
    }
    plaginInfo[@"subPlagins"] = subPlArray;
    
    [array addObject:plaginInfo];
}

+ (NSString *)grabInfoPlistPathFromFolderWithPath:(NSString *)folderPath {
    NSArray *folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    
    for (NSString *folderItem in folderContent) {
        if ([folderItem isEqualToString:@"grabInfo.plist"]) {
            NSString *itemPath = [folderPath stringByAppendingPathComponent:folderItem];
            return itemPath;
        }
    }
    
    return nil;
}

+ (NSArray *)subFoldersPathsFromFolderWithPath:(NSString *)folderPath {
    NSMutableArray *subFoldersPaths = [NSMutableArray array];
    NSArray *folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    
    for (NSString *folderItem in folderContent) {
        NSString *itemPath = [folderPath stringByAppendingPathComponent:folderItem];
        
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                [subFoldersPaths addObject:itemPath];
            }
        }
    }
    
    return subFoldersPaths;
}

+ (void)paths:(NSMutableArray *)array toPlaginWithName:(NSString *)name fromFolder:(NSString *)folderPath {
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory]) {
        if (isDirectory) {
            NSArray *folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
            
            for (NSString *folderItem in folderContent) {
                if ([folderItem isEqualToString:@".DS_Store"] == NO) {
                    NSString *itemPath = [folderPath stringByAppendingPathComponent:folderItem];
                    [self paths:array toPlaginWithName:name fromFolder:itemPath];
                }
            }
        } else if ([folderPath.lastPathComponent isEqualToString:@"grabInfo.plist"]) {
            NSString *pathToPlaginWithName = [folderPath stringByDeletingLastPathComponent];
            
            if ([pathToPlaginWithName.lastPathComponent isEqualToString:name]) {
                [array addObject:pathToPlaginWithName];
            }
        }
    }
}

@end
