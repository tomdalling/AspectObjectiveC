## About AspectObjectiveC

AspectObjectiveC (AOC) brings aspect oriented programming functionality
to objective c. Basically, it allows you to execute arbitrary code
before, instead of, or after any method on any class at runtime. It is
available under the MIT license (see LICENSE.txt).

## Current Status

AOC is still in its very early stages. It is however usable at the
moment. Build the DemoApp target, try it out, and have a look through
he code (it's quite small).

AOC currently requires:

 - i386 or x86_64 architecture
 - OSX 10.5+

The current limitations are:

 - Methods that return structures, or take structures as arguments, 
   are not supported (i.e. No NSRect/NSPoint/NSSize)
 - Advice for a method must be installed before the method is called,
   and never removed. This is because <code>valueForKey:</code> caches
   IMPs, which can cause crashes.
 - May not work for class methods (instance methods only)
 - May not work for variadic functions

## Future Development

The most important features are:

 - Support for common structures as return values and arguments 
   (NSRect/NSPoint/NSSize)
 
The less important, but possible, features are:

 - Support for ppc architecture
 - OSX 10.4 support
 - Allow advice to be installed an uninstalled at any time.
   This would require swizzling <code>valueForKey:</code> which could
   cause performance issues.
 - Support class methods
 - Support variadic functions