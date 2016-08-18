//
//  CHIPDFTextState.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFTextState.h"

@implementation CHIPDFTextState

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.characterSpacing = 0;
        self.wordSpacing = 0;
        self.horizontalScaling = 1.0;
        self.leading = 0;
        self.font = nil;
        self.fontSize = 0;
        self.renderingMode = 0;
        self.textRise = 0;
    }
    
    return self;
}

@end
