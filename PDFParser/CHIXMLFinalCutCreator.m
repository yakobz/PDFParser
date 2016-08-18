//
//  CHIXMLFinalCutCreator.m
//  PDFParser
//
//  Created by Yakov on 8/17/16.
//  Copyright © 2016 Andrew Danileyko. All rights reserved.
//

#import "CHIXMLFinalCutCreator.h"
#import "CHIBuilderPlaginsInfoArray.h"
#import "ASUtilites.h"

@implementation CHIXMLFinalCutCreator

+ (NSXMLDocument *)createXMLWithContentPath:(NSString *)contentPath {
    NSXMLElement *rootElement = [[NSXMLElement alloc] initWithXMLString:@"<fcpxml version=\"1.5\"></fcpxml>" error:nil];
    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
    
    NSArray *plaginsInfo = [CHIBuilderPlaginsInfoArray plaginsArrayForContentWithPath:contentPath];
    NSLog(@"%@", plaginsInfo);
    
    [self setHeaderForXMLDocument:xmlDocument];
    [self setDocTypeForXMLDocument:xmlDocument];
    [self addResourcesForRootElement:rootElement withPlaginsArray:plaginsInfo];
    [self addLibraryForRootElement:rootElement withPlaginsArray:plaginsInfo stringDate:contentPath.lastPathComponent];

    return xmlDocument;
}

#pragma mark - Setting XML Content

+ (void)setHeaderForXMLDocument:(NSXMLDocument *)xmlDocument {
    [xmlDocument setVersion:@"1.0"];
    [xmlDocument setCharacterEncoding:@"UTF-8"];
    [xmlDocument setStandalone:NO];
}

+ (void)setDocTypeForXMLDocument:(NSXMLDocument *)xmlDocument {
    NSXMLDTD *xmlDocType = [[NSXMLDTD alloc] init];
    [xmlDocType setName:@"fcpxml"];
    [xmlDocument setDTD:xmlDocType];
}

#pragma mark - Fill Resources

+ (void)addResourcesForRootElement:(NSXMLElement *)rootElement withPlaginsArray:(NSArray *)plaginsArray {
    NSXMLElement *resourcesElement = [[NSXMLElement alloc] initWithName:@"resources"];
    
    [self addFormatElementToResourcesElement:resourcesElement];
    
    [rootElement addChild:resourcesElement];
}

+ (void)addFormatElementToResourcesElement:(NSXMLElement *)resourcesElement {

}

#pragma mark - Fill Library

+ (void)addLibraryForRootElement:(NSXMLElement *)rootElement withPlaginsArray:(NSArray *)plaginsArray stringDate:(NSString *)stringDate {
    NSString *moviesFolderPath = NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES)[0];
    NSString *libraryPath = [moviesFolderPath stringByAppendingPathComponent:@"Motion Projects/Library.fcpbundle"];
    
    NSString *libraryElementXMLSting = [NSString stringWithFormat:@"<library location=\"%@\"></library>", libraryPath];
    NSXMLElement *libraryElement = [[NSXMLElement alloc] initWithXMLString:libraryElementXMLSting error:nil];
    
    NSString *eventElementXMLString = [NSString stringWithFormat:@"<event name=\"Recording From %@\" uid=\"%@\"></event>", stringDate, [ASUtilites GUID]];
    NSXMLElement *eventElement = [[NSXMLElement alloc] initWithXMLString:eventElementXMLString error:nil];
    [libraryElement addChild:eventElement];
    
    [self addProjectsElementsToEventElement:eventElement fromPlaginsArray:plaginsArray];
    [self addSmartCollectionInfoToLibraryElement:libraryElement];
    
    [rootElement addChild:libraryElement];
}

+ (void)addProjectsElementsToEventElement:(NSXMLElement *)eventElement fromPlaginsArray:(NSArray *)plaginsArray {
    for (NSUInteger i = 0; i < plaginsArray.count; i++) {
        NSDictionary *projectInfo = plaginsArray[i];
        
        NSString *projectElementXMLString = [NSString stringWithFormat:@"<project name=\"%@ Recording\" uid=\"%@\"></project>", projectInfo[@"name"], [ASUtilites GUID]];
        NSXMLElement *projectElement = [[NSXMLElement alloc] initWithXMLString:projectElementXMLString error:nil];
        [eventElement addChild:projectElement];
        
        NSString *sequenceDuration = [self sequenceDurationWithContentFolder:projectInfo[@"paths"][0]];
        NSString *sequenceElementXMLString = [NSString stringWithFormat:@"<sequence duration=\"%@s\" format=\"r%lu\" tcStart=\"0s\" tcFormat=\"NDF\" audioLayout=\"stereo\" audioRate=\"48k\"></sequence>", sequenceDuration, (unsigned long)(i + 1)];
        NSXMLElement *sequenceElement = [[NSXMLElement alloc] initWithXMLString:sequenceElementXMLString error:nil];
        [projectElement addChild:sequenceElement];
        
        NSXMLElement *spineElement = [[NSXMLElement alloc] initWithName:@"spine"];
        [sequenceElement addChild:spineElement];
        
        [self addVideoElementToSpineElement:spineElement duration:sequenceDuration refId:plaginsArray.count + i + 1 refClipName:projectInfo[@"name"] lane:i + 1];
    }
}

+ (void)addVideoElementToSpineElement:(NSXMLElement *)spineElement duration:(NSString *)duration refId:(NSUInteger)refId refClipName:(NSString *)refClipName lane:(NSInteger)lane {
    NSString *videoElementXMLString = [NSString stringWithFormat:@"<video name=\"Replace with video file\" offset=\"0s\" ref=\"r%lu\" duration=\"%@s\"></video>", refId, duration];
    NSXMLElement *videoElement = [[NSXMLElement alloc] initWithXMLString:videoElementXMLString error:NSIllegalTextMovement];
    [spineElement addChild:videoElement];
    
    NSString *colorElementXMLString = @"<param name=\"Color\" key=\"9999/10008/10006/2/1/1\" value=\"0 0 0\"></param>";
    NSXMLElement *colorElement = [[NSXMLElement alloc] initWithXMLString:colorElementXMLString error:nil];
    
    NSSize mainWindowSize = [NSScreen mainScreen].frame.size;
    
    NSString *widthElementXMLString = [NSString stringWithFormat:@"<param name=\"Width\" key=\"9999/10008/10006/2/1/300\" value=\"%.0f=\"></param>", mainWindowSize.width];
    NSXMLElement *widthElement = [[NSXMLElement alloc] initWithXMLString:widthElementXMLString error:nil];
    
    NSString *heightElementXMLString = [NSString stringWithFormat:@"<param name=\"Height\" key=\"9999/10008/10006/2/1/301\" value=\"%.0f\"></param>", mainWindowSize.height];
    NSXMLElement *heightElement = [[NSXMLElement alloc] initWithXMLString:heightElementXMLString error:nil];
    
    NSString *refClipElementXMLString = [NSString stringWithFormat:@"<ref-clip name=\"%@ Recording Clip %lu\" lane=\"%lu\" offset=\"0s\" ref=\"r%lu\" duration=\"%@s\"></ref-clip>", refClipName, refId + 1, lane, refId + 1, duration];
    NSXMLElement *refClipElement = [[NSXMLElement alloc] initWithXMLString:refClipElementXMLString error:nil];

    [videoElement setChildren:@[colorElement, widthElement, heightElement, refClipElement]];
}

+ (void)addSmartCollectionInfoToLibraryElement:(NSXMLElement *)libraryElement {
    NSXMLElement *projectsElement = [[NSXMLElement alloc] initWithXMLString:@"<smart-collection name=\"Projects\" match=\"all\"></smart-collection>" error:nil];
    NSXMLElement *projectsRuleElement = [[NSXMLElement alloc] initWithXMLString:@"<match-clip rule=\"is\" type=\"project\"></match-clip>" error:nil];
    [projectsElement addChild:projectsRuleElement];
    
    NSXMLElement *allVideoElement = [[NSXMLElement alloc] initWithXMLString:@"<smart-collection name=\"All Video\" match=\"any\"></smart-collection>" error:nil];
    NSXMLElement *videoOnlyRuleElement = [[NSXMLElement alloc] initWithXMLString:@"<match-media rule=\"is\" type=\"videoOnly\"></match-media>" error:nil];
    NSXMLElement *videoWithAudioRuleElement = [[NSXMLElement alloc] initWithXMLString:@"<match-media rule=\"is\" type=\"videoWithAudio\"></match-media>" error:nil];
    [allVideoElement setChildren:@[videoOnlyRuleElement, videoWithAudioRuleElement]];
    
    NSXMLElement *audioElement = [[NSXMLElement alloc] initWithXMLString:@"<smart-collection name=\"Audio Only\" match=\"all\"></smart-collection>" error:nil];
    NSXMLElement *audioRuleElement = [[NSXMLElement alloc] initWithXMLString:@"<match-media rule=\"is\" type=\"audioOnly\"></match-media>" error:nil];
    [audioElement addChild:audioRuleElement];
    
    NSXMLElement *stillsElement = [[NSXMLElement alloc] initWithXMLString:@"<smart-collection name=\"Stills\" match=\"all\"></smart-collection>" error:nil];
    NSXMLElement *stillsRuleElement = [[NSXMLElement alloc] initWithXMLString:@"<match-media rule=\"is\" type=\"stills\"></match-media>" error:nil];
    [stillsElement addChild:stillsRuleElement];
    
    NSXMLElement *favoritesElement = [[NSXMLElement alloc] initWithXMLString:@"<smart-collection name=\"Favorites\" match=\"all\"></smart-collection>" error:nil];
    NSXMLElement *favoritesRatingsElement = [[NSXMLElement alloc] initWithXMLString:@"<match-ratings value=\"favorites\"></match-ratings>" error:nil];
    [favoritesElement addChild:favoritesRatingsElement];
    
    [libraryElement addChild:projectsElement];
    [libraryElement addChild:allVideoElement];
    [libraryElement addChild:audioElement];
    [libraryElement addChild:stillsElement];
    [libraryElement addChild:favoritesElement];
}

#pragma mark - Utils

+ (NSString *)idForNewElementWithParentElement:(NSXMLElement *)parentElement {
    return [NSString stringWithFormat:@"id=\"r%@\"", @(parentElement.childCount + 1)];
}

+ (NSString *)sequenceDurationWithContentFolder:(NSString *)contentFolder {
    NSArray *contentFolderSubfolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contentFolder error:nil];

    NSString *frame = @"0";
    for (NSString *framePath in contentFolderSubfolders) {
        NSString *newFrame = framePath.lastPathComponent;
        frame = newFrame.integerValue > frame.integerValue ? newFrame : frame;
    }
    
    NSString *sequenceDuration = [NSString stringWithFormat:@"%f", (frame.integerValue / 24.0) * 1.001];
    return sequenceDuration;
}

#pragma mark - Writing XML To File

+ (void)writeXMLDocument:(NSXMLDocument *)xmlDocument toFileWithPath:(NSString *)filePath {
    NSData *xmlData = [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
    
    if (![xmlData writeToFile:filePath atomically:YES]) {
        NSLog(@"CHIXMLFinalCutCreator:writeXMLDocument:toFileWithPath: can't write file");
    }
}

@end
