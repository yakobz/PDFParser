//
//  CHIPDFRenderView.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHIPDFPath;

@interface CHIPDFRenderView : NSView

@property (nonatomic, strong) CHIPDFPath *clipPath;
@property (nonatomic, strong) CHIPDFPath *drawPath;

@end
