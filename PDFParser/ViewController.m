//
//  ViewController.m
//  PDFParser
//
//  Created by Andrew Danileyko on 12.07.16.
//  Copyright © 2016 Andrew Danileyko. All rights reserved.
//

#import "ViewController.h"
#import "CHIPDFParser.h"
#import "CHIXMLFinalCutCreator.h"

@interface ViewController () <CHIPDFParserProtocol>

@property (weak, nonatomic) IBOutlet NSView *_uiTestView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
    [self test2];
    // Do any additional setup after loading the view.
}

- (void)test2 {
    NSString *desktopDirectory = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)[0];
    NSString *xmlFilePath = [desktopDirectory stringByAppendingPathComponent:@"testXML.fcpxml"];
    
    NSString *downloadFolderPath = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0];
    NSString *contentPath = [downloadFolderPath stringByAppendingPathComponent:@"15.08.2016_16-16-21.605/15.08.2016_16-16-21.605"];
    
    NSXMLDocument *xmlDocument = [CHIXMLFinalCutCreator createXMLWithContentPath:contentPath];
    [CHIXMLFinalCutCreator writeXMLDocument:xmlDocument toFileWithPath:xmlFilePath];
}

- (void)test {
    CHIPDFParser *parser = [[CHIPDFParser alloc] init];

    NSString *downloadFolderPath = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0];
    NSString *folderPath = [downloadFolderPath stringByAppendingPathComponent:@"15.08.2016_16-16-21.605"];
    [self parseAllPdfWithSubfoldersFromFolder:folderPath withParser:parser];
}

- (void)parseAllPdfWithSubfoldersFromFolder:(NSString *)parentFolderPath withParser:(CHIPDFParser *)parser {
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSLog(@"%@", parentFolderPath);
    
    BOOL isDirectory;
    if ([defaultFileManager fileExistsAtPath:parentFolderPath isDirectory:&isDirectory]) {
        if (isDirectory) {
            NSArray *folderContent = [defaultFileManager contentsOfDirectoryAtPath:parentFolderPath error:nil];
            
            for (NSString *folderItem in folderContent) {
                NSLog(@"%@", folderItem);
                if ([folderItem isEqualToString:@".DS_Store"] == NO) {
                    NSString *itemPath = [parentFolderPath stringByAppendingPathComponent:folderItem];
                    [self parseAllPdfWithSubfoldersFromFolder:itemPath withParser:parser];
                }
            }
        } else if ([parentFolderPath.pathExtension isEqualToString:@"pdf"]) {
            [parser parseWithURL:[NSURL fileURLWithPath:parentFolderPath]];
        }
    }
}

- (void)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            CHIPDFParser *parser = [[CHIPDFParser alloc] init];
            parser.delegate = self;
            [parser parseWithURL:panel.URLs[0]];
        }
    }];
}

#pragma mark - CHIPDFParser Protocol

- (void)PDFParser:(CHIPDFParser *)parser didCreateView:(NSView *)view {
    for (NSView *view in self._uiTestView.subviews) {
        [view removeFromSuperview];
    }
    
    view.frame = NSMakeRect(self._uiTestView.bounds.size.width / 2 - view.bounds.size.width / 2, self._uiTestView.bounds.size.height / 2 - view.bounds.size.height / 2, view.bounds.size.width, view.bounds.size.height);
    view.wantsLayer = YES;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[NSColor blackColor] CGColor];
    [self._uiTestView addSubview:view];
}

@end
