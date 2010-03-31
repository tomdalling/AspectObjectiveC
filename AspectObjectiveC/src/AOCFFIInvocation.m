
#import "AOCFFIInvocation.h"


#pragma mark -
#pragma mark AOCFFIInvocation(Private)

@interface AOCFFIInvocation(Private)
-(void) _privateInitWithCif:(ffi_cif*)cif arguments:(void**)argPtrs imp:(IMP)imp returnValue:(void*)returnValue;
@end

@implementation AOCFFIInvocation(Private)

-(void) _privateInitWithCif:(ffi_cif*)cif arguments:(void**)argPtrs imp:(IMP)imp returnValue:(void*)returnValue;
{
    _imp = imp;
    _cif = cif;
    _returnValue = malloc([self returnValueSize]);
    if(returnValue != NULL)
        memcpy(_returnValue, returnValue, [self returnValueSize]);
    
    _args = malloc(sizeof(void*) * _cif->nargs);
    NSUInteger argIdx = 0;
    for(argIdx = 0; argIdx < _cif->nargs; ++argIdx){
        _args[argIdx] = malloc(_cif->arg_types[argIdx]->size);
        memcpy(_args[argIdx], argPtrs[argIdx], _cif->arg_types[argIdx]->size);
    }
}

@end


#pragma mark -
#pragma mark AOCFFIInvocation

@implementation AOCFFIInvocation

-(id) initWithCif:(ffi_cif*)cif arguments:(void**)argPtrs imp:(IMP)imp;
{
    NSParameterAssert(cif != NULL);
    NSParameterAssert(argPtrs != NULL);
    NSParameterAssert(cif->nargs >= 2); //objc method has min of 2 args (self and _cmd)
    NSParameterAssert(cif->arg_types[0] == &ffi_type_pointer); //self must be a ptr
    NSParameterAssert(cif->arg_types[1] == &ffi_type_pointer); //_cmd must be a ptr
    NSParameterAssert(*((id*)argPtrs[0]) != nil); //self must not be nil
    NSParameterAssert(*((SEL*)argPtrs[1]) != NULL); //_cmd must not be NULL
    
    self = [super init];
    if(self == nil)
        return nil;
   
    [self _privateInitWithCif:cif arguments:argPtrs imp:imp returnValue:NULL];
    
    return self;
}

#pragma mark <AOCInvocationProtocol>

-(void) setSelector:(SEL)selector;
{
    [self setArgument:&selector atIndex:1];
}

-(SEL) selector;
{
    SEL selector = NULL;
    [self getArgument:&selector atIndex:1];
    return selector;
}

-(void) setTarget:(id)target;
{
    [self setArgument:&target atIndex:0];
}

-(id) target;
{
    id target = nil;
    [self getArgument:&target atIndex:0];
    return target;
}

-(IMP) imp;
{
    return _imp;
}

-(void) setImp:(IMP)imp;
{
    _imp = imp;
}

-(void) setArgument:(void*)argPtr atIndex:(NSUInteger)idx;
{
    if(argPtr == NULL)
        return;
    
    if(idx >= _cif->nargs)
        return;
    
    memcpy(_args[idx], argPtr, _cif->arg_types[idx]->size);
}

-(void) getArgument:(void*)argPtr atIndex:(NSUInteger)idx;
{
    if(argPtr == NULL)
        return;
    
    if(idx >= _cif->nargs)
        return;
    
    memcpy(argPtr, _args[idx], _cif->arg_types[idx]->size);
}

-(void) setReturnValue:(void*)returnValPtr;
{
    if(returnValPtr == NULL)
        return;
    
    memcpy(_returnValue, returnValPtr, _cif->rtype->size);
}

-(void) getReturnValue:(void*)returnValPtr;
{
    if(returnValPtr == NULL)
        return;
    
    memcpy(returnValPtr, _returnValue, _cif->rtype->size);
}

-(size_t) returnValueSize;
{
    return MAX(_cif->rtype->size, sizeof(long));
}

-(void) invoke;
{
    IMP impToInvoke = _imp ? _imp : [[self target] methodForSelector:[self selector]];
    if(impToInvoke == NULL)
        return;
    
    ffi_call(_cif, FFI_FN(impToInvoke), _returnValue, _args);
}

#pragma mark NSObject

-(id) init;
{
    self = [super init];
    
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:[NSString stringWithFormat:@"Don't use -[%@ %@]", [self className], NSStringFromSelector(_cmd)]
                           userInfo:nil] raise];
    
    [self release]; self = nil;
    return nil;
}

-(void) dealloc;
{
    NSUInteger argIdx = 0;
    for(argIdx = 0; argIdx < _cif->nargs; ++argIdx){
        free(_args[argIdx]);
    }
    free(_args);
    free(_returnValue);
    [super dealloc];
}

#pragma mark <NSCopying>

-(id) copyWithZone:(NSZone*)zone;
{
    AOCFFIInvocation* copy = [[self class] allocWithZone:zone];
    [copy _privateInitWithCif:_cif arguments:_args imp:_imp returnValue:_returnValue];
    return copy;
}

@end
