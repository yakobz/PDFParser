//
//  CHIPDFTextState.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTextRenderingModeStateFill 0
#define kTextRenderingModeStateStroke 1
#define kTextRenderingModeStateFillAndStroke 2
#define kTextRenderingModeClear 3
#define kTextRenderingModeStateFillAndAddToClipping 4
#define kTextRenderingModeStateStrokeAndAddToClipping 5
#define kTextRenderingModeStateFillAndStrokeAndAddToClipping 6
#define kTextRenderingModeClearAndAddToClipping 7

@interface CHIPDFTextState : NSObject

@property (nonatomic) double characterSpacing;
@property (nonatomic) double wordSpacing;
@property (nonatomic) double horizontalScaling;
@property (nonatomic) double leading; // межстрочное расстояние
@property (nonatomic, strong) NSString *font;
@property (nonatomic) double fontSize;
@property (nonatomic) int renderingMode;
@property (nonatomic) double textRise;

@end
