#
# Generates test cases for TestAOCMethodHooking
#

TYPE_INFO = {
    "id" => { :ivar => "m_id", :method_suffix => "Id", :nsvalue_wrapper => "%s" },
    "Class" => { :ivar => "m_class", :method_suffix => "Class", :nsvalue_wrapper => "%s" },
    "SEL" => { :ivar => "m_sel", :method_suffix => "SEL" }, #KVC doesn't work with SEL values
    "char" => { :ivar => "m_chr", :method_suffix => "Char", :nsvalue_wrapper => "[NSNumber numberWithChar:%s]" },
    "unsigned char" => { :ivar => "m_uchr", :method_suffix => "UChar", :nsvalue_wrapper => "[NSNumber numberWithUnsignedChar:%s]" },
    "short" => { :ivar => "m_shrt", :method_suffix => "Short", :nsvalue_wrapper => "[NSNumber numberWithShort:%s]" },
    "unsigned short" => { :ivar => "m_ushrt", :method_suffix => "UShort", :nsvalue_wrapper => "[NSNumber numberWithUnsignedShort:%s]" },
    "int" => { :ivar => "m_int", :method_suffix => "Int", :nsvalue_wrapper => "[NSNumber numberWithInt:%s]" },
    "unsigned int" => { :ivar => "m_uint", :method_suffix => "UInt", :nsvalue_wrapper => "[NSNumber numberWithUnsignedInt:%s]" },
    "long" => { :ivar => "m_long", :method_suffix => "Long", :nsvalue_wrapper => "[NSNumber numberWithLong:%s]" },
    "unsigned long" => { :ivar => "m_ulong", :method_suffix => "ULong", :nsvalue_wrapper => "[NSNumber numberWithUnsignedLong:%s]" },
    "long long" => { :ivar => "m_longLong", :method_suffix => "LongLong", :nsvalue_wrapper => "[NSNumber numberWithLongLong:%s]" },
    "unsigned long long" => { :ivar => "m_ulongLong", :method_suffix => "ULongLong", :nsvalue_wrapper => "[NSNumber numberWithUnsignedLongLong:%s]" },
    "float" => { :ivar => "m_float", :method_suffix => "Float", :nsvalue_wrapper => "[NSNumber numberWithFloat:%s]" },
    "double" => { :ivar => "m_double", :method_suffix => "Double", :nsvalue_wrapper => "[NSNumber numberWithDouble:%s]" },
    #"_Bool" => { :ivar => "m_bool", :method_suffix => "_Bool", :nsvalue_wrapper => "[NSNumber numberWithBool:(BOOL)%s]" },
    "void*" => { :ivar => "m_ptr", :method_suffix => "Ptr" }, #KVC doesn't work with arbitrary pointer values
    "char*" => { :ivar => "m_charPtr", :method_suffix => "CharPtr" },  #KVC doesn't work with arbitrary pointer values
    "NSRect" => { :ivar => "m_rect", :method_suffix => "NSRect", :nsvalue_wrapper => "[NSValue valueWithRect:%s]" },
    "NSPoint" => { :ivar => "m_point", :method_suffix => "NSPoint", :nsvalue_wrapper => "[NSValue valueWithPoint:%s]"},
    "NSSize" => { :ivar => "m_size", :method_suffix => "NSSize", :nsvalue_wrapper => "[NSValue valueWithSize:%s]"},
}

TEST_VALUES = {
    "id" => ["self", "nil", "[NSDate dateWithTimeIntervalSince1970:0]"],
    "Class" => ["NULL", "[NSDate class]"],
    "SEL" => ["NULL", "@selector(fake:selector:)"],
    "char" => ["CHAR_MAX", "'a'", "CHAR_MIN"],
    "unsigned char" => ["UCHAR_MAX", "'z'", "0"],
    "short" => ["SHRT_MAX", "333", "0", "-333", "SHRT_MIN"],
    "unsigned short" => ["USHRT_MAX", "55", "0"],
    "int" => ["INT_MAX", "0", "-144", "INT_MIN"],
    "unsigned int" => ["UINT_MAX", "60000", "0"],
    "long" => ["LONG_MAX", "800", "0", "LONG_MIN"],
    "unsigned long" => ["ULONG_MAX", "1337", "0"],
    "long long" => ["LONG_LONG_MAX", "3376", "0", "-872", "LONG_LONG_MIN"],
    "unsigned long long" => ["ULONG_LONG_MAX", "ULONG_LONG_MAX - 64", "0"],
    "float" => ["FLT_MAX", "FLT_MAX - 33.0f", "0.0f", "-123.4f", "FLT_MIN"],
    "double" => ["DBL_MAX", "66.0", "0.0", "DBL_MIN + 44.0", "DBL_MIN"],
    #"_Bool" => ["true", "false"],
    "void*" => ["NULL", "self", "(void*)0xDEADBEEF"],
    "char*" => ["NULL", "\"hello\""],
    "NSRect" => ["NSZeroRect", "NSMakeRect(1,2,3,4)"],
    "NSPoint" => ["NSZeroPoint", "NSMakePoint(7,9)"],
    "NSSize" => ["NSZeroSize", "NSMakeSize(2,5)"],
}

ALLOWED_ARG_TYPES = ["id", "Class", "SEL", "char", "unsigned char", "short",
                     "unsigned short", "int", "unsigned int", "long", 
                     "unsigned long", "long long", "unsigned long long",
                     "float", "double", "void*", "char*", "NSRect", "NSPoint",
                     "NSSize"]
                        
ALLOWED_RETURN_TYPES = ALLOWED_ARG_TYPES; # + ["void"]
            
# Asserting that above data is corret ##############            

def AssertTypesExistInHash(typeList, theHash)
    typeList.each do |type|
        if theHash[type].nil?
            abort("Type not found: #{type}")
        end
    end
end

AssertTypesExistInHash(ALLOWED_RETURN_TYPES, TYPE_INFO);
AssertTypesExistInHash(ALLOWED_RETURN_TYPES, TYPE_INFO);
AssertTypesExistInHash(ALLOWED_ARG_TYPES, TEST_VALUES);
AssertTypesExistInHash(ALLOWED_ARG_TYPES, TEST_VALUES);


# Helper functions ####################

def PrintReturnMethod(returnType, suffix2)
    ivar = TYPE_INFO[returnType][:ivar]
    suffix = TYPE_INFO[returnType][:method_suffix]
    puts "-(#{returnType}) return#{suffix}#{suffix2}; {"
    puts "    NSLog(@\"inside %@\", NSStringFromSelector(_cmd));"
    puts "    return #{ivar};"
    puts "}"
end

def PrintReturnMethodTests(returnType)
    ivar = TYPE_INFO[returnType][:ivar]
    suffix = TYPE_INFO[returnType][:method_suffix]
    TEST_VALUES[returnType].each_index do |idx|
        testValue = TEST_VALUES[returnType][idx];
        puts "-(void) testReturn#{suffix}#{idx+1};{"
        puts "    STAssertFalse(g_hookDidRun, @\"Hook shouldn't have run yet\");"
        puts "    #{ivar} = #{testValue};"
        puts "    STAssertEquals([self return#{suffix}], #{ivar}, @\"Return value is mangled\");"
        puts "    STAssertTrue(g_hookDidRun, @\"Hook should have run by now\");"
        puts "}"
    end
end

def PrintKVCAccessors(returnType)
    PrintReturnMethod(returnType, "KVCAccessorUnhooked")
    PrintReturnMethod(returnType, "KVCAccessorHooked")
end

def PrintKVCAccessorTest(returnType, accessorSuffix)
    ivar = TYPE_INFO[returnType][:ivar]
    suffix = TYPE_INFO[returnType][:method_suffix]
    nsvalue_wrapper = TYPE_INFO[returnType][:nsvalue_wrapper]
    if(nsvalue_wrapper.nil?)
        puts "// #{returnType} is an invalid type of KVC value, so it's not tested"
    else
        TEST_VALUES[returnType].each_index do |idx|
            testValue = TEST_VALUES[returnType][idx]
            wrapped = nsvalue_wrapper % testValue;
            puts "-(void) test#{accessorSuffix}#{suffix}#{idx+1};{"
            puts "    #{ivar} = #{testValue};"
            puts "    id retVal = [self valueForKey:@\"return#{suffix}#{accessorSuffix}\"];"
            puts "    id expected = #{wrapped};"
            puts "    STAssertEqualObjects(retVal, expected, @\"KVC accessor is broken\");"
            puts "}"
        end
    end
end

def PrintKVCAccessorTests(returnType)
    puts "//hey"
    PrintKVCAccessorTest(returnType, "KVCAccessorUnhooked")
    puts "//ho"
    PrintKVCAccessorTest(returnType, "KVCAccessorHooked")
    puts "//jo"
end

def PrintArgMethod(argType)
    ivar = TYPE_INFO[argType][:ivar]
    suffix = TYPE_INFO[argType][:method_suffix]
    puts "-(void) assertArgEqualOfType#{suffix}:(#{argType})arg;{"
    puts "    STAssertEquals(arg, #{ivar}, @\"Argument is mangled\");"
    puts "}"
end

def PrintArgMethodTests(argType)
    ivar = TYPE_INFO[argType][:ivar]
    suffix = TYPE_INFO[argType][:method_suffix]
    TEST_VALUES[argType].each_index do |idx|
        testValue = TEST_VALUES[argType][idx]
        puts "-(void) testArgEqualFor#{suffix}#{idx+1}; {"
        puts "    STAssertFalse(g_hookDidRun, @\"Hook shouldn't have run yet\");"
        puts "    #{ivar} = #{testValue};"
        puts "    [self assertArgEqualOfType#{suffix}:#{ivar}];"
        puts "    STAssertTrue(g_hookDidRun, @\"Hook should have run by now\");"
        puts "}"
    end
end

def PrintArgInstallMethod(argType)
    suffix = TYPE_INFO[argType][:method_suffix]
    ivar = TYPE_INFO[argType][:ivar]
    puts "-(void) installMethodForArgType#{suffix}:(#{argType})arg;{"
    puts "    NSLog(@\"Inside %@\", NSStringFromSelector(_cmd));"
    puts "}"
end

def PrintInstallMethodTest(type, returnOrArg, selector)
    suffix = TYPE_INFO[type][:method_suffix]
    puts "-(void) testInstallAndUninstallFor#{returnOrArg}Type#{suffix}; {"
    puts "    SEL selector = @selector(#{selector});"
    puts "    [self doTestInstallAndUninstallForSelector:selector];"
    puts "}"
end



# Actual printing starts here ##########################

puts "/***************************************"
puts " * This was generated by #{File.basename(__FILE__)}"
puts " * Don't edit this section because it will be overwritten on next build"
puts " * Edit #{File.basename(__FILE__)} instead"
puts " ***************************************/"

puts "#pragma mark Return value tests"

ALLOWED_RETURN_TYPES.each do |returnType|
    puts "// #{returnType} /////////////////////////"
    PrintReturnMethod(returnType, "")
    PrintReturnMethodTests(returnType)
    #PrintKVCAccessors(returnType)
    #PrintKVCAccessorTests(returnType)
    PrintReturnMethod(returnType, "ForInstall")
    suffix = TYPE_INFO[returnType][:method_suffix]
    PrintInstallMethodTest(returnType, "Return", "return#{suffix}ForInstall")
    puts "\n\n"
end

puts "#pragma mark Argument value tests"

ALLOWED_ARG_TYPES.each do |argType|
    puts "// #{argType} /////////////////////////"
    PrintArgMethod(argType)
    PrintArgMethodTests(argType)
    PrintArgInstallMethod(argType)
    suffix = TYPE_INFO[argType][:method_suffix]
    PrintInstallMethodTest(argType, "Arg", "installMethodForArgType#{suffix}:")
    puts "\n\n"
end

puts "#pragma mark Initialisation code"
puts "//Call this from +(void)initialize"
puts "+(void) initializeNecessaryHooks; {"
puts "    NSLog(@\"begin %@\", NSStringFromSelector(_cmd));"
puts "    //return methods"
ALLOWED_RETURN_TYPES.each do |returnType|
    suffix = TYPE_INFO[returnType][:method_suffix]
    puts "    AOCInstallHook(MockHookForTesting, NULL, [self class], @selector(return#{suffix}), nil);"
    puts "    AOCInstallHook(MockHookForTesting, NULL, [self class], @selector(return#{suffix}KVCAccessorHooked), nil);"
end
puts "    //arg methods"
ALLOWED_ARG_TYPES.each do |argType|
    suffix = TYPE_INFO[argType][:method_suffix]
    puts "    AOCInstallHook(MockHookForTesting, NULL, [self class], @selector(assertArgEqualOfType#{suffix}:), nil);"
end
puts "}"


