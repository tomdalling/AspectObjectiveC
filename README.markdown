## About AspectObjectiveC

AspectObjectiveC (AOC) brings aspect oriented programming functionality to objective c.
Basically, it allows you to execute arbitrary code before, instead of, or after any method
on any class at runtime.

## Current Status

AOC is still in its very early stages. It is however
usable at the moment **only on i386**. Build the DemoApp
target, try it out, and have a look through the code (it's quite
small).

The current limitations are:

 - Only works on i386
 - Methods that return structures, or take structures as arguments, 
   are not supported (i.e. No NSRect/NSPoint/NSSize)
 - Advice for a method must be installed before the method is called, and never removed.
   This is because <code>valueForKey:</code> caches IMPs, which can cause crashes.
 - May not work for class methods (instance methods only)
 - May not work for variadic functions

## Future Development

The most important features are:

 - Support for i386 and x86_64 architectures (maybe ppc)
 - Support for common structures as return values and arguments (NSRect/NSPoint/NSSize)
 
The less important, but possible, features are:

 - Allow advice to be installed an uninstalled at any time.
   This would require swizzling <code>valueForKey:</code> which could cause performance issues.
 - Support class methods
 - Support variadic functions