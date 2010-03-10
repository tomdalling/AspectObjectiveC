
#import "IntegrityOfReturnAndArgsTest.h"
#import "AOCMethodHooking.h"

static BOOL g_hookDidRun = NO;

void DummyHookForTesting(NSInvocation* inv)
{
	g_hookDidRun = YES;
	[inv invoke];
}


@implementation IntegrityOfReturnAndArgsTest

#define MAKE_RETURN_METHOD(TYPE,IVAR,SUFFIX) \
	-(TYPE) return ## SUFFIX; \
	{ \
		return (IVAR);\
	}

#define MAKE_ARG_METHOD(TYPE, IVAR, SUFFIX) \
	-(void) assertArgEqualFor ## SUFFIX:(TYPE)arg; \
	{ \
		STAssertEquals(arg, (IVAR), @"Argument is mangled in %@", NSStringFromSelector(_cmd));\
	}

#define MAKE_RETURN_AND_ARG_METHOD(TYPE, IVAR, SUFFIX) \
	MAKE_RETURN_METHOD(TYPE, IVAR, SUFFIX) \
	MAKE_ARG_METHOD(TYPE, IVAR, SUFFIX)

MAKE_RETURN_AND_ARG_METHOD(id, m_id, Id)
MAKE_RETURN_AND_ARG_METHOD(Class, m_class, Class)
MAKE_RETURN_AND_ARG_METHOD(SEL, m_sel, SEL)
MAKE_RETURN_AND_ARG_METHOD(char, m_chr, Char)
MAKE_RETURN_AND_ARG_METHOD(unsigned char, m_uchr, UChar)
MAKE_RETURN_AND_ARG_METHOD(short, m_shrt, Short)
MAKE_RETURN_AND_ARG_METHOD(unsigned short, m_ushrt, UShort)
MAKE_RETURN_AND_ARG_METHOD(int, m_int, Int)
MAKE_RETURN_AND_ARG_METHOD(unsigned int, m_uint, UInt)
MAKE_RETURN_AND_ARG_METHOD(long, m_long, Long)
MAKE_RETURN_AND_ARG_METHOD(unsigned long, m_ulong, ULong)
MAKE_RETURN_AND_ARG_METHOD(long long, m_longLong, LongLong)
MAKE_RETURN_AND_ARG_METHOD(unsigned long long, m_ulongLong, ULongLong)
MAKE_RETURN_AND_ARG_METHOD(float, m_float, Float)
MAKE_RETURN_AND_ARG_METHOD(double, m_double, Double)
MAKE_RETURN_AND_ARG_METHOD(_Bool, m_bool, _Bool)
MAKE_RETURN_AND_ARG_METHOD(void*, m_ptr, Ptr)
MAKE_RETURN_AND_ARG_METHOD(char*, m_charPtr, CharPtr)

#define MAKE_ARG_TEST(IVAR, SUFFIX, SUFFIX2, VALUE) \
	-(void) testArgEqualFor ## SUFFIX ## SUFFIX2; \
	{ \
		STAssertFalse(g_hookDidRun, @"Hook shouldn't have run yet"); \
		(IVAR) = (VALUE); \
		[self assertArgEqualFor ## SUFFIX:(IVAR)];\
		STAssertTrue(g_hookDidRun, @"Hook should have run by now"); \
	}

#define MAKE_RETURN_TEST(IVAR, SUFFIX, SUFFIX2, VALUE) \
	-(void) testReturn ## SUFFIX ## SUFFIX2; \
	{ \
		STAssertFalse(g_hookDidRun, @"Hook shouldn't have run yet"); \
		(IVAR) = (VALUE); \
		STAssertEquals([self return ## SUFFIX], (IVAR), @"Return value is mangled from %@", NSStringFromSelector(_cmd)); \
		STAssertTrue(g_hookDidRun, @"Hook should have run by now"); \
	}

#define MAKE_RETURN_AND_ARG_TEST(IVAR, SUFFIX, SUFFIX2, VALUE) \
	MAKE_ARG_TEST(IVAR, SUFFIX, SUFFIX2, VALUE) \
	MAKE_RETURN_TEST(IVAR, SUFFIX, SUFFIX2, VALUE)

MAKE_RETURN_AND_ARG_TEST(m_id, Id, A, self);
MAKE_RETURN_AND_ARG_TEST(m_id, Id, B, [NSDate dateWithTimeIntervalSinceNow:3.0]);
MAKE_RETURN_AND_ARG_TEST(m_id, Id, C, nil);

MAKE_RETURN_AND_ARG_TEST(m_class, Class, A, [NSDate class])
MAKE_RETURN_AND_ARG_TEST(m_class, Class, B, nil)

MAKE_RETURN_AND_ARG_TEST(m_sel, SEL, A, @selector(fake:selector:))
MAKE_RETURN_AND_ARG_TEST(m_sel, SEL, B, NULL)

MAKE_RETURN_AND_ARG_TEST(m_chr, Char, A, CHAR_MAX)
MAKE_RETURN_AND_ARG_TEST(m_chr, Char, B, 'a')
MAKE_RETURN_AND_ARG_TEST(m_chr, Char, C, CHAR_MIN)

MAKE_RETURN_AND_ARG_TEST(m_uchr, UChar, A, UCHAR_MAX)
MAKE_RETURN_AND_ARG_TEST(m_uchr, UChar, B, 'z')
MAKE_RETURN_AND_ARG_TEST(m_uchr, UChar, C, 0)

MAKE_RETURN_AND_ARG_TEST(m_shrt, Short, A, SHRT_MIN)
MAKE_RETURN_AND_ARG_TEST(m_shrt, Short, B, 333)
MAKE_RETURN_AND_ARG_TEST(m_shrt, Short, C, SHRT_MAX)

MAKE_RETURN_AND_ARG_TEST(m_ushrt, UShort, A, USHRT_MAX)
MAKE_RETURN_AND_ARG_TEST(m_ushrt, UShort, B, 55)
MAKE_RETURN_AND_ARG_TEST(m_ushrt, UShort, C, 0)

MAKE_RETURN_AND_ARG_TEST(m_int, Int, A, INT_MAX)
MAKE_RETURN_AND_ARG_TEST(m_int, Int, B, -144)
MAKE_RETURN_AND_ARG_TEST(m_int, Int, C, 0)
MAKE_RETURN_AND_ARG_TEST(m_int, Int, D, INT_MIN)

MAKE_RETURN_AND_ARG_TEST(m_uint, UInt, A, UINT_MAX)
MAKE_RETURN_AND_ARG_TEST(m_uint, UInt, B, 60000)
MAKE_RETURN_AND_ARG_TEST(m_uint, UInt, C, 0)

MAKE_RETURN_AND_ARG_TEST(m_long, Long, A, LONG_MAX)
MAKE_RETURN_AND_ARG_TEST(m_long, Long, B, 800)
MAKE_RETURN_AND_ARG_TEST(m_long, Long, C, 0)
MAKE_RETURN_AND_ARG_TEST(m_long, Long, D, LONG_MIN)

MAKE_RETURN_AND_ARG_TEST(m_ulong, ULong, A, ULONG_MAX)
MAKE_RETURN_AND_ARG_TEST(m_ulong, ULong, B, 1337)
MAKE_RETURN_AND_ARG_TEST(m_ulong, ULong, C, 0)

MAKE_RETURN_AND_ARG_TEST(m_longLong, LongLong, A, LONG_LONG_MAX)
MAKE_RETURN_AND_ARG_TEST(m_longLong, LongLong, B, 3376)
MAKE_RETURN_AND_ARG_TEST(m_longLong, LongLong, C, 0)
MAKE_RETURN_AND_ARG_TEST(m_longLong, LongLong, D, -827)
MAKE_RETURN_AND_ARG_TEST(m_longLong, LongLong, E, LONG_LONG_MIN)

MAKE_RETURN_AND_ARG_TEST(m_ulongLong, ULongLong, A, ULONG_LONG_MAX)
MAKE_RETURN_AND_ARG_TEST(m_ulongLong, ULongLong, B, ULONG_LONG_MAX - 64)
MAKE_RETURN_AND_ARG_TEST(m_ulongLong, ULongLong, C, 0)

MAKE_RETURN_AND_ARG_TEST(m_float, Float, A, FLT_MAX)
MAKE_RETURN_AND_ARG_TEST(m_float, Float, B, FLT_MAX - 33.0f)
MAKE_RETURN_AND_ARG_TEST(m_float, Float, C, 0.0f)
MAKE_RETURN_AND_ARG_TEST(m_float, Float, D, -123.0f)
MAKE_RETURN_AND_ARG_TEST(m_float, Float, E, FLT_MIN)

MAKE_RETURN_AND_ARG_TEST(m_double, Double, A, DBL_MAX)
MAKE_RETURN_AND_ARG_TEST(m_double, Double, B, 66.0)
MAKE_RETURN_AND_ARG_TEST(m_double, Double, C, 0)
MAKE_RETURN_AND_ARG_TEST(m_double, Double, D, DBL_MIN + 44.0)
MAKE_RETURN_AND_ARG_TEST(m_double, Double, E, DBL_MIN)

MAKE_RETURN_AND_ARG_TEST(m_bool, _Bool, A, true)
MAKE_RETURN_AND_ARG_TEST(m_bool, _Bool, B, false)

MAKE_RETURN_AND_ARG_TEST(m_ptr, Ptr, A, NULL)
MAKE_RETURN_AND_ARG_TEST(m_ptr, Ptr, B, self)
MAKE_RETURN_AND_ARG_TEST(m_ptr, Ptr, C, (void*)0xDEADBEEF)

MAKE_RETURN_AND_ARG_TEST(m_charPtr, CharPtr, A, NULL)
MAKE_RETURN_AND_ARG_TEST(m_charPtr, CharPtr, B, "hello")

-(void) setUp;
{
	g_hookDidRun = NO;
	AOCSetGlobalInvocationHook(DummyHookForTesting);
}

+(void) initialize;
{
	if (self == [IntegrityOfReturnAndArgsTest class]) {
#		define INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(SUFFIX) \
			AOCInstallHook([self class], @selector(return ## SUFFIX), nil); \
			AOCInstallHook([self class], @selector(assertArgEqualFor ## SUFFIX:), nil);
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Id)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Class)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(SEL)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Char)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(UChar)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Short)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(UShort)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Int)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(UInt)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Long)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(ULong)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(LongLong)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(ULongLong)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Float)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Double)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(_Bool)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(Ptr)
		INSTALL_HOOK_FOR_RETURN_AND_ARG_METHODS(CharPtr)
    }
}
@end
