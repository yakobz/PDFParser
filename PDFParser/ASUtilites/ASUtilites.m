//
//  ASUtilites.m
//  TokensApp
//
//  Created by  IOS DEV ad-sys on 30.10.14.
//  Copyright (c) 2014  IOS DEV ad-sys. All rights reserved.
//

#import "ASUtilites.h"
//#import "SSKeychain.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "mach/mach.h"
#import <objc/runtime.h>

@implementation ASUtilites

#pragma mark - IDs

+ (NSString *)GUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *guid = (__bridge NSString *)string;
    CFRelease(string);
    return guid;
}

+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

+ (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}

#pragma mark - Memory Utils

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

+ (vm_size_t)memoryUsed {
    return usedMemory();
}

#pragma mark - Misc

+ (void)clearCache {
    NSString *folderPath = NSTemporaryDirectory();
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    if (array.count > 0) {
        for (NSString *name in array) {
            NSString *path = [folderPath stringByAppendingPathComponent:name];
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
}

+ (BOOL)isSupportedExtention:(NSString *)ext fromArray:(NSArray *)exts {
    NSString *upperExt = [ext uppercaseString];
    if ([upperExt hasPrefix:@"."]) {
        upperExt = [upperExt substringFromIndex:1];
    }
    if ([exts indexOfObject:upperExt] != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (BOOL)isSupportedImageExtention:(NSString *)ext {
    return [self isSupportedExtention:ext fromArray:@[@"JPG", @"JPEG", @"PNG"]];
}

+ (BOOL)isSupportedVideoExtention:(NSString *)ext {
    return [self isSupportedExtention:ext fromArray:@[@"MOV", @"MP4", @"AVI"]];
}

#pragma mark - Video

+ (BOOL)isVideoExists {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *path = [def objectForKey:@"lastSessionPath"];
    
    if (path) {
        NSData *sessionData = [NSData dataWithContentsOfURL:[[NSURL fileURLWithPath:path] URLByAppendingPathComponent:@"session.plist"]];
        if (sessionData) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Check If Application Is Running

+ (BOOL)applicationIsRunning {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier].count > 1) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Close All Windows

+ (void)closeAllWindows {
    NSWindow *menuWindow = [NSApplication sharedApplication].windows.firstObject;
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        if ([window isEqual:menuWindow] == NO) {
            [window close];
        }
    }
}

@end