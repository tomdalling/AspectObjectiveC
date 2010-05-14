
/*! 
    @mainpage AspectObjectiveC
 
    @section about_sec About AspectObjectiveC

        AspectObjectiveC (AOC) brings aspect oriented programming functionality
        to objective c. Basically, it allows you to execute arbitrary code
        before, instead of, or after any method on any class at runtime. It is
        available under the MIT license (see LICENSE.txt).
 
        Created by <a href="http://www.tomdalling.com/">Tom Dalling</a>.

    @section current_sec Current Status

        AOC is not ready for release just yet. It is, however, usable at the
        moment. Build the DemoApp target, try it out, and have a look through
        he code (it's quite small).

        AOC currently requires:

        <ul>
            <li>i386 or x86_64 architecture</li>
            <li>OSX 10.5+</li>
        </ul>
        
        It may work on 10.4 (i386 only, needs older version of GCC) and on the
        iPhone SDK, but neither have been tested. I'm interested to know if it
        can compile and pass the unit tests on the iPhone and on 10.4, so if you
        try, let me know how it goes.

        The current limitations are:

        <ul>
            <li>Advice for a method must be installed before the method is called,
                and never removed. This is because <code>valueForKey:</code> caches
                IMPs, which can cause crashes.</li>
            <li>May not work for class methods (instance methods only)</li>
            <li>May not work for variadic functions</li>
            <li>Not thread safe, so be careful with multithreaded code.</li>
        </ul>

    @section future_sec Future Development

        Possible future work includes:

        <ul>
            <li>Support for ppc architecture</li>
            <li>OSX 10.4 support</li>
            <li>Allow advice to be installed an uninstalled at any time.
                This would require swizzling <code>valueForKey:</code> which could
                cause performance issues.</li>
            <li>Support class methods</li>
            <li>Support variadic functions</li>
        </ul>
 
    @section doc_sec API Documentation
        
        Use the navigation at the top of the page to browse the API documentation.
        
        A docset for XCode integration is also available in the "doc" folder.
 
    @section example_sec Example Usage
    
        TODO: put example code here
 */

