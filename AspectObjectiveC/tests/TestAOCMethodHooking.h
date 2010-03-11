
#import <SenTestingKit/SenTestingKit.h>


@interface TestAOCMethodHooking : SenTestCase {
	id m_id;
	Class m_class;
	SEL m_sel;
	char m_chr;
	unsigned char m_uchr;
	short m_shrt;
	unsigned short m_ushrt;
	int m_int;
	unsigned int m_uint;
	long m_long;
	unsigned long m_ulong;
	long long m_longLong;
	unsigned long long m_ulongLong;
	float m_float;
	double m_double;
	_Bool m_bool;
	void* m_ptr;
	char* m_charPtr;
}

@end
