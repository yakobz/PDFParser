//
//  CHIPDFGraphicsState.h
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 21.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHIPDFTextState.h"

@interface CHIPDFGraphicsState : NSObject <NSCopying>

@property (nonatomic) CGAffineTransform ctm; // Матрица трансформации объектов рендеринга
@property (nonatomic) CGColorSpaceRef colorSpace; // световая схема
@property (nonatomic) CGColorRef colorStroke;
@property (nonatomic) CGColorRef colorFill;
@property (nonatomic, strong) CHIPDFTextState *textState; // Натсройки вывода текста
@property (nonatomic) double lineWidth;
@property (nonatomic) int lineCap; // форма завершающих линию точек
@property (nonatomic) int lineJoin; // форма соединяющих сегменты линии точек
@property (nonatomic, strong) id dashPattern; // паттерн линии типа --- -- --- -- --- и тп
@property (nonatomic) int blendMode; // режим наложения прозрачных объектов
@property (nonatomic, strong) NSDictionary *softMask;
@property (nonatomic) double alphaConstant;
@property (nonatomic) BOOL alphaSource;
@property (nonatomic, strong) NSView *view;

- (void)reset;
- (void)concatenateMatrix:(CGAffineTransform)matrix;

@end
