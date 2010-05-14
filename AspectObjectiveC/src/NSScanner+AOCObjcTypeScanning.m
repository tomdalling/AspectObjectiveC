
#import "NSScanner+AOCObjcTypeScanning.h"
#import <objc/runtime.h>


#pragma mark -
#pragma mark NSScanner(AOCObjcTypeScanningPrivate)

@interface NSScanner(AOCObjcTypeScanningPrivate)
-(NSCharacterSet*) _AOC_objcTypeQualifierChars;
-(NSCharacterSet*) _AOC_atomicTypeChars;
-(BOOL) _AOC_scanSingleCharFromSet:(NSCharacterSet*)charSet intoString:(NSString**)outString;
-(BOOL) _AOC_scanSingleChar:(unichar)singleChar;
-(BOOL) _AOC_scanNestedBrackets:(NSString**)outTypeString openingBracket:(unichar)openingBracket closingBracket:(unichar)closingBracket;
-(BOOL) _AOC_scanCompositeType:(NSString**)outTypeString;
-(BOOL) _AOC_scanPointerType:(NSString**)outTypeString;
-(BOOL) _AOC_scanStructType:(NSString**)outTypeString;
-(BOOL) _AOC_scanArrayType:(NSString**)outTypeString;
-(BOOL) _AOC_scanBitfieldType:(NSString**)outTypeString;
-(BOOL) _AOC_scanUnionType:(NSString**)outTypeString;
@end

@implementation NSScanner(AOCObjcTypeScanningPrivate)

-(NSCharacterSet*) _AOC_objcTypeQualifierChars;
{
    return [[NSCharacterSet characterSetWithCharactersInString:@"rnNoORV"] retain];
}

-(NSCharacterSet*) _AOC_atomicTypeChars;
{
    return [NSCharacterSet characterSetWithCharactersInString:@"cislqCISLQfdBv*@#:?"];
}

-(BOOL) _AOC_scanSingleCharFromSet:(NSCharacterSet*)charSet intoString:(NSString**)outString;
{
    if([self scanLocation] >= [[self string] length])
        return NO;
    
    unichar singleChar = [[self string] characterAtIndex:[self scanLocation]];
    if(![charSet characterIsMember:singleChar])
        return NO;
    
    [self setScanLocation:[self scanLocation]+1];
    if(outString)
        *outString = [NSString stringWithCharacters:&singleChar length:1];
    return YES;
}

-(BOOL) _AOC_scanSingleChar:(unichar)singleChar;
{
    if([self scanLocation] >= [[self string] length])
        return NO;
    
    if(singleChar != [[self string] characterAtIndex:[self scanLocation]])
        return NO;
    
    [self setScanLocation:[self scanLocation]+1];
    return YES;
}

-(BOOL) _AOC_scanNestedBrackets:(NSString**)outTypeString openingBracket:(unichar)openingBracket closingBracket:(unichar)closingBracket;
{
    NSUInteger firstCharIdx = [self scanLocation];
    if([[self string] characterAtIndex:firstCharIdx] != openingBracket)
        return NO;
    
    NSString* str = [self string];
    NSUInteger strLen = [str length];
    NSUInteger structBracketStack = 1;
    NSUInteger i = firstCharIdx + 1;
    while(YES){
        if(i >= strLen)
            return NO; //went off the end
        
        unichar ch = [str characterAtIndex:i];
        if(ch == openingBracket){
            ++structBracketStack;
        } else if(ch == closingBracket){
            --structBracketStack;
            if(structBracketStack == 0){
                break; //found closing bracket
            }
        }
        
        ++i;
    }
    
    ++i;
    [self setScanLocation:i];
    
    if(outTypeString != NULL){
        NSRange structRange = NSMakeRange(firstCharIdx, i - firstCharIdx);
        *outTypeString = [str substringWithRange:structRange];
    }
    return YES;
}

-(BOOL) _AOC_scanCompositeType:(NSString**)outTypeString;
{
    if([self _AOC_scanPointerType:outTypeString])
        return YES;
    if([self _AOC_scanStructType:outTypeString])
        return YES;
    if([self _AOC_scanArrayType:outTypeString])
        return YES;
    if([self _AOC_scanBitfieldType:outTypeString])
        return YES;
    if([self _AOC_scanUnionType:outTypeString])
        return YES;
    
    return NO;
}

-(BOOL) _AOC_scanPointerType:(NSString**)outTypeString;
{
    NSUInteger firstCharIdx = [self scanLocation];
    
    if(![self _AOC_scanSingleChar:_C_PTR])
        return NO;
    
    if(![self scanObjcType:nil]){
        [self setScanLocation:firstCharIdx];
        return NO;
    }
    
    if(outTypeString){
        NSRange pointerTypeRange = NSMakeRange(firstCharIdx, [self scanLocation] - firstCharIdx);
        *outTypeString = [[self string] substringWithRange:pointerTypeRange];
    }
    return YES;
}

-(BOOL) _AOC_scanStructType:(NSString**)outTypeString;
{
    return [self _AOC_scanNestedBrackets:outTypeString 
                          openingBracket:_C_STRUCT_B 
                          closingBracket:_C_STRUCT_E];
}

-(BOOL) _AOC_scanArrayType:(NSString**)outTypeString;
{
    return [self _AOC_scanNestedBrackets:outTypeString
                          openingBracket:_C_ARY_B
                          closingBracket:_C_ARY_E];
}

-(BOOL) _AOC_scanBitfieldType:(NSString**)outTypeString;
{
    NSUInteger originalLocation = [self scanLocation];
    
    if(![self _AOC_scanSingleChar:_C_BFLD])
        return NO;
    
    if(![self scanInt:NULL]){
        [self setScanLocation:originalLocation];
        return NO;
    }
    
    return YES;
}

-(BOOL) _AOC_scanUnionType:(NSString**)outTypeString;
{
    return [self _AOC_scanNestedBrackets:outTypeString
                          openingBracket:_C_UNION_B
                          closingBracket:_C_UNION_E];
}

@end



#pragma mark -
#pragma mark NSScanner(AOCObjcTypeScanning)

@implementation NSScanner(AOCObjcTypeScanning)

-(BOOL)scanObjcType:(NSString**)outObjcType;
{
    NSUInteger originalLocation = [self scanLocation];
    
    //skip qualifiers
    [self scanCharactersFromSet:[self _AOC_objcTypeQualifierChars] intoString:nil];
    
    //try scan atomic type
    if([self _AOC_scanSingleCharFromSet:[self _AOC_atomicTypeChars] intoString:outObjcType])
        return YES;
    
    //try scan composite type
    if([self _AOC_scanCompositeType:outObjcType])
        return YES;
    
    [self setScanLocation:originalLocation];
    return NO;
}

@end
