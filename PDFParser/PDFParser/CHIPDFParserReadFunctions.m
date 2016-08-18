//
//  CHIPDFParserReadFunctions.m
//  LayeredScreenRecorder
//
//  Created by Andrew Danileyko on 13.06.16.
//  Copyright © 2016 Erwan Barrier. All rights reserved.
//

#import "CHIPDFParserReadFunctions.h"
#import "CHIPDFRef.h"

@implementation CHIPDFParserReadFunctions

+ (id)readNextEntityFromFIle:(FILE *)file {
    char c;
    do  {
        c = fgetc(file);
    } while (c == ' ');
    
    if (c == '<') { // dictionary or string
        char next_c = fgetc(file);
        if (next_c == '<') { // dictionary
            return [CHIPDFParserReadFunctions readDictionary:file];
        } else { // string
            fseek(file, -1, SEEK_CUR);
            return [CHIPDFParserReadFunctions readString:file openBrace:'<' closeBrace:'>'];
        }
    } else {
        if (c == '(') { //string
            return [CHIPDFParserReadFunctions readString:file openBrace:'(' closeBrace:')'];
        } else {
            if (c == '[') { // array
                return [CHIPDFParserReadFunctions readArray:file];
            } else {
                if (c == 't' || c == 'f') { // bool
                    if (c == 't') {
                        fseek(file, 3, SEEK_CUR);
                        return @(YES);
                    } else {
                        fseek(file, 4, SEEK_CUR);
                        return @(NO);
                    }
                } else {
                    if ((c >= '0' && c <= '9') || c == '+' || c == '-') { // bool
                        return [CHIPDFParserReadFunctions readNumber:file];
                    } else {
                        if (c == '/') { // name
                            return [CHIPDFParserReadFunctions readName:file];
                        } else {
                            if (c == 'R') { // ref
                                return @"R";
                            } else {
                                //
                            }
                        }
                    }
                }
            }
        }
    }
    
    return @"";
}

+ (NSString *)readString:(FILE *)file openBrace:(char)openBrace closeBrace:(char)closeBrace {
    NSString *result;
    int opened = 1;
    fpos_t positionStart;
    fgetpos(file, &positionStart);
    do {
        char c = fgetc(file);
        if (c == openBrace) {
            opened ++;
        } else {
            if (c == closeBrace) {
                opened --;
                if (opened == 0) {
                    fpos_t position;
                    fgetpos(file, &position);
                    fsetpos(file, &positionStart);
                    fpos_t length = position - positionStart - 1;
                    char *buffer = (char *)malloc(length + 1);
                    memset(buffer, 0, length + 1);
                    fread(buffer, 1, length, file);
                    result = [NSString stringWithFormat:@"%s", buffer];
                    fseek(file, 1, SEEK_CUR);
                    free(buffer);
                    break;
                }
            }
        }
    } while (YES);
    
    return result;
}

+ (NSString *)readName:(FILE *)file {
    NSString *result = @"";
    fpos_t positionStart;
    fgetpos(file, &positionStart);
    do {
        char c = fgetc(file);
        if (c == ' ' || c == '\n' || c == '\r' || c == '\t' || c == '\0') {
            fpos_t position;
            fgetpos(file, &position);
            fsetpos(file, &positionStart);
            fpos_t length = position - positionStart - 1;
            char *buffer = (char *)malloc(length + 1);
            memset(buffer, 0, length + 1);
            fread(buffer, 1, length, file);
            result = [NSString stringWithFormat:@"%s", buffer];
            free(buffer);
            break;
        }
    } while (YES);
    
    return result;
}

+ (NSNumber *)readNumber:(FILE *)file {
    fpos_t positionStart;
    fgetpos(file, &positionStart);
    positionStart -= 1;
    fsetpos(file, &positionStart);
    NSNumber *result = @(0);
    BOOL real = NO;;
    
    do {
        char c = fgetc(file);
        if ((c < '0' || c > '9') && c != '+' && c != '-' && c != '.') { // bool
            fpos_t position;
            fgetpos(file, &position);
            fsetpos(file, &positionStart);
            fpos_t length = position - positionStart - 1;
            char *buffer = (char *)malloc(length + 1);
            memset(buffer, 0, length + 1);
            fread(buffer, 1, length, file);
            NSString *string = [NSString stringWithFormat:@"%s", buffer];
            free(buffer);
            result = real ? @([string doubleValue]) : @([string integerValue]);
            break;
        } else {
            if (c == '.') {
                real = YES;
            }
        }
    } while (YES);
    
    return result;
}

+ (NSDictionary *)readDictionary:(FILE *)file {
    NSMutableArray *tempValues = [NSMutableArray array];
    char c, nextC;
    do {
        do  {
            c = fgetc(file);
        } while (c == ' ' || c == '\n' || c == '\r' || c == '\t' || c == '\0');
        nextC = fgetc(file);

        if (c == '>' && nextC == '>') {
            break;
        }
        fseek(file, -2, SEEK_CUR);
    
        id entity = [self readNextEntityFromFIle:file];
        if (entity) {
            [tempValues addObject:entity];
        }
    } while (YES);
    
    for (NSInteger i = tempValues.count - 1; i >= 0; i--) {
        id value = tempValues[i];
        if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"R"]) {
            CHIPDFRef *ref = [[CHIPDFRef alloc] init];
            ref.name = [NSString stringWithFormat:@"%@ %@", tempValues[i - 2], tempValues[i - 1]];
            [tempValues removeObjectAtIndex:i];
            [tempValues removeObjectAtIndex:i - 1];
            [tempValues removeObjectAtIndex:i - 2];
            i -= 2;
            [tempValues insertObject:ref atIndex:i];
        }
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (int i = 0; i < tempValues.count; i += 2) {
        result[tempValues[i]] = tempValues[i + 1];
    }
    
    return result;
}

+ (NSArray *)readArray:(FILE *)file {
    NSMutableArray *result = [NSMutableArray array];
    char c;
    do {
        do  {
            c = fgetc(file);
        } while (c == ' ' || c == '\n' || c == '\r' || c == '\t' || c == '\0');
        if (c == ']') {
            break;
        }
        fseek(file, -1, SEEK_CUR);
        
        id entity = [self readNextEntityFromFIle:file];
        if (entity) {
            [result addObject:entity];
        }
    } while (YES);
    
    for (NSInteger i = result.count - 1; i >= 0; i--) {
        id value = result[i];
        if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"R"]) {
            CHIPDFRef *ref = [[CHIPDFRef alloc] init];
            ref.name = [NSString stringWithFormat:@"%@ %@", result[i - 2], result[i - 1]];
            [result removeObjectAtIndex:i];
            [result removeObjectAtIndex:i - 1];
            [result removeObjectAtIndex:i - 2];
            i -= 2;
            [result insertObject:ref atIndex:i];
        }
    }
    
    return result;
}

+ (NSData *)readStream:(FILE *)file {
    NSData *data;
    int flag = 0;
    fpos_t position;
    fgetpos(file, &position);
    do {
        char c = fgetc(file);
        if (c == 's' || c == 't' || c == 'r' || c == 'e' || c == 'a' || c == 'm') {
            flag ++;
            if (flag == 6) {
                break;
            }
        } else {
            flag = 0;
        }
    } while (YES);
    fpos_t positionFinish;
    fgetpos(file, &positionFinish);
    fseek(file, position, SEEK_SET);
    fpos_t length = positionFinish - position - 10;
    char *buffer = malloc(length);
    memset(buffer, 0, length);
    fread(buffer, 1, length, file);
    data = [NSData dataWithBytes:buffer length:length];
    free(buffer);
    
    return data;
}

+ (NSArray *)readxRefInFile:(FILE *)file {
    NSInteger offset = [self xrefOffsetInFile:file];
    if (offset == 0) {
        return nil;
    }
    

    fseek(file, offset, SEEK_SET);
    
    NSMutableArray *_xref = [NSMutableArray array];
    NSString *line = [self readNextLineAsNSStringFromFile:file];
    if ([line isEqualToString:@"xref"]) {
        NSArray *components;
        do {
            line = [self readNextLineAsNSStringFromFile:file];
            if ([line isEqualToString:@"trailer"]) {
                break;
            } else {
                components = [line componentsSeparatedByString:@" "];
                int count = [components[1] intValue];
                for (int i = 0; i < count; i++) {
                    line = [self readNextLineAsNSStringFromFile:file];
                    components = [line componentsSeparatedByString:@" "];
                    if ([components[2] isEqualToString:@"n"]) {
                        [_xref addObject:components[0]];
                    }
                }
            }
        } while (YES);
    }
    return _xref;
}

+ (NSInteger)xrefOffsetInFile:(FILE *)file {
    fseek(file, 0, SEEK_END);
    
    NSString *line;
    do {
        line = [CHIPDFParserReadFunctions readPrevLineAsNSStringFromFile:file];
    } while (![line isEqualToString:@"startxref"]);
    
    [CHIPDFParserReadFunctions readNextLineAsNSStringFromFile:file];
    NSString *offset = [CHIPDFParserReadFunctions readNextLineAsNSStringFromFile:file];
    return [offset integerValue];
}

+ (NSDictionary *)readTrailerFile:(FILE *)file {
    fseek(file, 0, SEEK_END);
    
    NSString *line;
    do {
        line = [CHIPDFParserReadFunctions readPrevLineAsNSStringFromFile:file];
    } while (![line isEqualToString:@"trailer"]);
    
    [CHIPDFParserReadFunctions readNextLineAsNSStringFromFile:file];
    NSDictionary *trailer = [CHIPDFParserReadFunctions readNextEntityFromFIle:file];
    return trailer;
}

+ (NSString *)readNextLineAsNSStringFromFile:(FILE *)file {
    char *line = NULL;
    size_t linecap = 0;
    getline(&line, &linecap, file);
    return [[NSString stringWithFormat:@"%s", line] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *)readPrevLineAsNSStringFromFile:(FILE *)file {
    char line[2048];
    line[0] = '\0';
    
    char c;
    int index = 0;
    fpos_t position = 0;
    fgetpos(file, &position);
    do {
        position--;
        fseek(file, -1, SEEK_CUR);
        c = fgetc(file);
        fseek(file, -1, SEEK_CUR);
        if (c != '\n') {
            line[index] = c;
            line[index + 1] = '\0';
            if (++index == 2046) {
                break;
            }
        }
    } while ((c != '\n' || index == 0) && position >= 0);
    fseek(file, 1, SEEK_CUR);
    
    for (int i = 0; i < index / 2; i++) {
        char c = line[i];
        line[i] = line[index - i - 1];
        line[index - i - 1] = c;
    }
    NSString *result = [NSString stringWithFormat:@"%s", line];
    return result;
}

@end
