
Tracer v1.0 by Solistra
==============================================================================

Summary
------------------------------------------------------------------------------
  This script provides a simple, customizable tracer which can be used as a
debugger or information-gathering tool for Ruby code. By default, the output
from the tracer shows a visual representation of the Ruby call stack with
relevant information. This is primarily a scripting and debugging tool.

Advanced Usage
------------------------------------------------------------------------------
  Essentially, this script is a wrapper around Ruby's +Kernel.set_trace_func+
method, which is a callback provided by the language when code is executed.
This script has been written as a tracer and simple debugger, but has great
potential to do much more than this. Your creativity and skill is the only
real limit to the possibilities.

  +Kernel.set_trace_func+ provides a great deal of information that can be
used by both the conditional and tracer provided by this script. Ruby's tracer
reports the *event* that was received ('c-call', 'c-return', 'call', 'return',
'class', 'end', 'line', and 'raise'); the *file* where the event occurred; the
*line* within that file; the *method* (or *id*) executed; the *binding* of the
method; and the *class* which it was executed in.

  Most of the information provided is largely self-explanatory, but the events
may need a little elaboration: 
  * 'c-call' is given when a C routine has been called.
  * 'c-return', likewise, occurs when a C routine returns.
  * 'call' is when a Ruby method is called.
  * 'return' would be when a Ruby method returns.
  * 'class' marks the opening of a new Ruby class or module.
  * 'end' finishes a class or module definition.
  * 'line' is given when code is executed on a new line.
  * 'raise' is received when an Exception is raised.

License
------------------------------------------------------------------------------
  This script is made available under the terms of the MIT Expat license. View
[this page](http://sesvxace.wordpress.com/license/) for more information.

Installation
------------------------------------------------------------------------------
  Place this script below Materials, but above Main. Place this script below
the SES Core (v2.0) script if you are using it.

