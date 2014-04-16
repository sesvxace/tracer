#--
# Tracer v1.3 by Solistra and Enelvon
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides a simple, customizable tracer which can be used as a
# debugger or information-gathering tool for Ruby code. By default, the output
# from the tracer shows a visual representation of the Ruby call stack with
# relevant information. This is primarily a scripting and debugging tool.
# 
# Usage
# -----------------------------------------------------------------------------
#   The tracer may be started either through a REPL or from a script call with
# the following:
# 
#     SES::Tracer.start
# 
#   You may also supply your own block of code for the tracer to run by simply
# passing a proc or lambda object as the argument (or running a block directly
# on the method):
# 
#     SES::Tracer.start do |event, file, line, id, binding, class_name|
#       if file =~ /^{(\d+)}/
#         file.gsub!(/^{\d+}/, SES::Tracer.scripts[$1.to_i])
#       end
#       printf("%8s %s:%-4d %20s %-20s\n", event, file, line, id, class_name)
#     end
# 
#   The tracer may be stopped through a REPL or from a script call with the
# following:
# 
#     SES::Tracer.stop
#
#   As of v1.3, you can specify methods that will always invoke the tracer when
# run through the use of the TRACE_METHODS hash. Its keys are the names of
# classes and its values are symbols corresponding to methods within the class.
# By default it will cause command_355 of Game_Interpreter to be traced. This
# is the "Script..." event command, which (without the help of the Tracer) will
# produce frustrating errors that point back to the command_355 method itself.
# 
# Advanced Usage
# -----------------------------------------------------------------------------
#   Essentially, this script is a wrapper around Ruby's 'Kernel.set_trace_func'
# method, which is a callback provided by the language when code is executed.
# This script has been written as a tracer and simple debugger, but has great
# potential to do much more than this. Your creativity and skill are the only
# real limits to the possibilities.
# 
#   'Kernel.set_trace_func' provides a great deal of information that can be
# used by both the conditional and tracer provided by this script. Ruby's
# tracer reports the *event* that was received ('c-call', 'c-return', 'call',
# 'return', 'class', 'end', 'line', and 'raise'); the *file* where the event
# occurred; the *line* within that file; the *method* (or *id*) executed; the
# *binding* of the method; and the *class* which it was executed in.
# 
#   Most of the information provided is largely self-explanatory, but events
# may need a little elaboration:
# 
# - 'c-call' is given when a C routine has been called.
# - 'c-return', likewise, occurs when a C routine returns.
# - 'call' is when a Ruby method is called.
# - 'return' would be when a Ruby method returns.
# - 'class' marks the opening of a new Ruby class or module.
# - 'end' finishes a class or module definition.
# - 'line' is given when code is executed on a new line.
# - 'raise' is received when an Exception is raised.
# 
#   Make use of this information however you see fit; remember, the only
# limitation to the power of the callback is how you choose to write your code
# around it.
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/) for more detailed
# information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below Materials, but above Main. Place this script below
# the SES Core (v2.0) script if you are using it.
# 
#++
module SES
  # ===========================================================================
  # Tracer
  # ===========================================================================
  # Defines operation and output of the SES Tracer. This is simply a moderate
  # wrapper around Ruby's 'Kernel.set_trace_func' method.
  module Tracer
    class << self
      attr_accessor :conditional, :tracer
      attr_reader   :scripts
    end
    # =========================================================================
    # BEGIN CONFIGURATION
    # =========================================================================
    # Whether or not to automatically start the tracer when playing the game in
    # test mode.
    # **NOTE:** the tracer can cause a significant amount of lag, particularly
    # when loading game data from disk in 'DataManager.init'.
    AUTO_RUN = false
    
    # A hash of methods (by class) that should always be watched by the Tracer.
    TRACE_METHODS = {
        # Class             # Array of Methods
        Game_Interpreter => [:command_355],
      }
    
    # Conditional used to determine the conditions under which @tracer should
    # perform. The tracer will not activate if this conditional evaluates to a 
    # +false+ or +nil+ value. Consult the Advanced Usage section in the header
    # for more information about the tracing values given to this lambda.
    @conditional = ->(event, file, line, id, binding, class_name) do
      # Return true when any code (C or Ruby) is called or returned.
      ['call', 'c-call', 'return', 'c-return'].any? { |value| event == value }
    end
    
    # Performs tracing operations and formats the output. This lambda is only
    # called if @conditional evaluates to a value other than +false+ or +nil+.
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
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    # Collects script names in the order they are placed within the Ace Script
    # Editor. Used in the Lambda block to provide script names for the +file+
    # variable used.
    @scripts = load_data('Data/Scripts.rvdata2').map! { |script| script[1] }
    
    # Provides the block used for tracing. By default, this lambda operates if
    # the defined @conditional evaluates to +true+, replaces the file names
    # given by Ace with script names, and calls the @tracer lambda.
    Lambda = ->(event, file, line, id, binding, class_name) do
      if @conditional.call(event, file, line, id, binding, class_name)
        file.gsub!(/^{\d+}/, @scripts[$1.to_i]) if file =~ /^{(\d+)}/
        @tracer.call(event, file, line, id, binding, class_name)
      end
    end
    
    # Starts the tracer with the given block (SES::Tracer::Lambda by default).
    def self.start(code = SES::Tracer::Lambda, &block)
      ::Kernel.set_trace_func(block_given? ? block : code)
    end
    class << self ; alias :run :start ; end
    
    # Stops the tracer by setting the trace block to +nil+.
    def self.stop
      ::Kernel.set_trace_func(nil)
    end
    class << self ; alias :pause :stop ; end
    
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      Description = Script.new(:Tracer, 1.3, :Solistra)
      Register.enter(Description)
    end
  end
end
# =============================================================================
# SceneManager
# =============================================================================
class << SceneManager
  # Aliased to redefine methods in the TRACE_METHODS hash. This redefinition
  # invokes the tracer whenever the specified methods are called.
  alias ses_tracer_sm_run run
  def run
    SES::Tracer::TRACE_METHODS.each_pair do |rclass, rmethods|
      rmethods.each do |m|
        m2 = rclass.instance_method(m)
        rclass.send(:define_method, m, Proc.new do
          SES::Tracer.start
          m2.bind(self).call
          SES::Tracer.stop
        end)
      end
    end
    # Automatically run the tracer if SES::Tracer::AUTO_RUN is set to a true
    # value and the game is being run in $TEST mode. The only code called in
    # RGSS3 before the tracer can begin is the `rgss_main` method, its
    # associated block, and the redefinition of automatically traced methods.
    SES::Tracer.run if SES::Tracer::AUTO_RUN && $TEST
    ses_tracer_sm_run
  end
end