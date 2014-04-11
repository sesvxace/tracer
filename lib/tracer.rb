#--
# Tracer v1.0 by Solistra
# ==============================================================================
# 
# Summary
# ------------------------------------------------------------------------------
#   This script provides a simple, customizable tracer which can be used as a
# debugger or information-gathering tool for Ruby code. By default, the output
# from the tracer shows a visual representation of the Ruby call stack with
# relevant information. This is primarily a scripting and debugging tool.
# 
# Advanced Usage
# ------------------------------------------------------------------------------
#   Essentially, this script is a wrapper around Ruby's +Kernel.set_trace_func+
# method, which is a callback provided by the language when code is executed.
# This script has been written as a tracer and simple debugger, but has great
# potential to do much more than this. Your creativity and skill is the only
# real limit to the possibilities.
# 
#   +Kernel.set_trace_func+ provides a great deal of information that can be
# used by both the conditional and tracer provided by this script. Ruby's tracer
# reports the *event* that was received ('c-call', 'c-return', 'call', 'return',
# 'class', 'end', 'line', and 'raise'); the *file* where the event occurred; the
# *line* within that file; the *method* (or *id*) executed; the *binding* of the
# method; and the *class* which it was executed in.
# 
#   Most of the information provided is largely self-explanatory, but the events
# may need a little elaboration: 
#   * 'c-call' is given when a C routine has been called.
#   * 'c-return', likewise, occurs when a C routine returns.
#   * 'call' is when a Ruby method is called.
#   * 'return' would be when a Ruby method returns.
#   * 'class' marks the opening of a new Ruby class or module.
#   * 'end' finishes a class or module definition.
#   * 'line' is given when code is executed on a new line.
#   * 'raise' is received when an Exception is raised.
# 
# License
# ------------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license. View
# [this page](http://sesvxace.wordpress.com/license/) for more information.
# 
# Installation
# ------------------------------------------------------------------------------
#   Place this script below Materials, but above Main. Place this script below
# the SES Core (v2.0) script if you are using it.
# 
#++
module SES
  # ============================================================================
  # Tracer
  # ============================================================================
  # Defines operation and output of the SES Tracer. This is simply a moderate
  # wrapper around Ruby's +Kernel.set_trace_func+ method.
  module Tracer
    class << self ; attr_accessor :conditional, :tracer ; end
    # ==========================================================================
    # BEGIN CONFIGURATION
    # ==========================================================================
    # Whether or not to automatically start the tracer when playing the game in
    # test mode.
    # **NOTE:** the tracer can cause a significant amount of lag, particularly
    # when loading game data from disk in +DataManager.init+.
    AUTO_RUN = false
    
    # Conditional used to determine the conditions under which @tracer should
    # perform. The tracer will not fire if this conditional evaluates to +false+
    # or +nil+. Consult the Advanced Usage section in the header for more
    # information about the tracing values given to this lambda.
    @conditional = ->(event, file, line, id, binding, class_name) do
      # Return true when any code (C or Ruby) is called or returned.
      ['call', 'c-call', 'return', 'c-return'].any? { |value| event == value }
    end
    
    # Performs tracing operations and formats the output. This lambda is only
    # called if +@conditional+ evaluates to a value other than +false+ or +nil+.
    # The +file+ variable passed to this lambda is a string containing the name
    # of the currently operating script being traced.
    @tracer = ->(event, file, line, id, binding, class_name) do
      @depth ||= 0 # Used to track the depth of the Ruby call stack.
      case event
      when /call/
        # Code has been called; print trace information and increase the depth
        # of the Ruby call stack.
        printf("%2s %5d %-20s", event[/^c-/] ? 'C' : 'rb', line, file)
        puts (' ' * @depth) << "#{class_name}.#{id}"
        @depth += 1
      when /return/
        # Code has returned a value; decrease the depth of the Ruby call stack.
        @depth -= 1 if @depth > 0
      end
    end
    # ==========================================================================
    # END CONFIGURATION
    # ==========================================================================
    # Collects script names in the order they are placed within the Ace Script
    # Editor. Used in the Lambda block to provide script names for the +file+
    # variable used.
    @scripts = load_data('Data/Scripts.rvdata2').map! { |script| script[1] }
    
    # Provides the block used for tracing. By default, this lambda operates if
    # the defined +@conditional+ evaluates to +true+, replaces the file names
    # given by Ace with script names, and calls the +@tracer+ lambda.
    Lambda = lambda do |event, file, line, id, binding, class_name|
      if @conditional.call(event, file, line, id, binding, class_name)
        file.gsub!(/^{\d+}/, @scripts[$1.to_i]) if file =~ /^{(\d+)}/
        @tracer.call(event, file, line, id, binding, class_name)
      end
    end
    
    # Starts the tracer with the given block (SES::Tracer::Lambda by default).
    def self.start(block = SES::Tracer::Lambda)
      ::Kernel.set_trace_func(block)
    end
    class << self ; alias :run :start ; end
    
    # Stops the tracer by setting the trace block to +nil+.
    def self.stop
      ::Kernel.set_trace_func(nil)
    end
    class << self ; alias :pause :stop ; end
    
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      Description = Script.new(:Tracer, 1.0, :Solistra)
      Register.enter(Description)
    end
  end
end
# ==============================================================================
# SceneManager
# ==============================================================================
if SES::Tracer::AUTO_RUN && $TEST
  module SceneManager
    class << self ; alias :ses_tracer_sm_run :run ; end
    
    # Aliased to automatically run the tracer if SES::Tracer::AUTO_RUN is set to
    # a true value and the game is being run in $TEST mode. The only code called
    # in RGSS3 before the tracer can begin is the +rgss_main+ method and its
    # associated block.
    def self.run(*args, &block)
      SES::Tracer.run
      ses_tracer_sm_run(*args, &block)
    end
  end
end