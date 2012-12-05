# Ruby/Mock version 1.0
# 
# A class for conveniently building mock objects in Test::Unit test cases. It is
# based on ideas in Ruby/Mock by Nat Pryce <nat.pryce@b13media.com>, which is a
# class for doing much the same thing for RUnit test cases.
#
# == Examples
#
# For the examples below, it is assumed that a hypothetical '<tt>Adapter</tt>'
# class is needed to test whatever class is being tested. It has two instance
# methods in addition to its initializer: <tt>read</tt>, which takes no
# arguments and returns data read from the adapted source, and <tt>write</tt>,
# which takes a String and writes as much as it can to the adapted destination,
# returning any that is left over.
#
#   # With the in-place mock-object constructor, you can make an instance of a
#   # one-off anonymous test class:
#   mockAdapter = Test::Unit::MockObject( Adapter ).new
#   
#   # Now set up some return values for the next test:
#   mockAdapter.setReturnValues( :read => "",
#                                :write => Proc::new {|data| data[-20,20]} )
#   
#   # Mandate a certain order to the calls
#   mockAdapter.setCallOrder( :read, :read, :read, :write, :read )
#
#   # Now start the mock object recording interactions with it
#   mockAdapter.activate
#
#   # Send the adapter to the tested object and run the tests
#   testedObject.setAdapter( mockAdapter )
#   ...
#
#   # Now check the order of method calls on the mock object against the expected
#   # order.
#   mockAdapter.verify
#
# If you require more advanced functionality in your mock class, you can also
# use the anonymous class returned by the Test::Unit::MockObject factory method
# as the superclass for your own mockup like this:
#
#   # Create a mocked adapter class
#   class MockAdapter < Test::Unit::MockObject( Adapter )
#
#		def initialize
#			super
#			setCallOrder( :read, :read, :read, :write, :read )
#		end
#
#       def read( *args )
#           @readargs = args
#           super # Call the mocked method to record the call
#       end
#
#       def write( *args )
#           @writeargs = args
#           super # Call the mocked method to record the call
#       end
#   end
#
# == Note
#
# All the testing and setup methods in the Test::Unit::Mockup class (the
# abstract class that new MockObjects inherit from) have two aliases for your
# convenience:
#
# * Each one has a double-underscore alias so that methods which collide with
#   them from the mocked class don't obscure them. Eg.,
#
#     mockAdapter.__setCallOrder( :read, :read, :read, :write, :read )
#
#   can be used instead of the call from the example above if the Adapter for
#   some reason already has a 'setCallOrder' instance method.
#
# * Non-camelCase versions of the methods are also provided. Eg.,
#
#     mockAdapter.set_call_order( :read, :read, :read, :write, :read )
#
#   will work, too. Double-underscored *and* non camelCased aliases are not
#   defined; if anyone complains, I'll add them.
#
# == Rcsid
#
# $Id: mock.rb,v 1.1 2004/03/24 02:40:30 neoneye Exp $
#
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
#
# 
#

require 'algorithm/diff'

require 'test/unit'
require 'test/unit/assertions'

module Test
	module Unit

		# The Regexp that matches methods which will not be mocked.
		UnmockedMethods = %r{^(
			__									# __id__, __call__, etc.
			|inspect							# Useful as-is for debugging, and hard to fake
			|kind_of\?|is_a\?|instance_of\?		# / Can't fake simply -- delegated to the
			|type|class							# \ actual underlying class
			|method|send|respond_to\?			# These will work fine as-is
			|hash								# There's no good way to fake this
		)}x

		### An abstract base class that provides the setup and testing methods
		### to concrete mock objects.
		class Mockup

			include Test::Unit::Assertions

			### Instantiate and return a new mock object after recording the
			### specified args.
			def initialize( *args )
				@args = args
				@calls = []
				@activated = nil
				@returnValues = Hash::new( true )
				@callOrder = []
				@strictCallOrder = false
			end


			#########################################################
			###	F A K E   T Y P E - C H E C K I N G   M E T H O D S
			#########################################################

			# Handle #type and #class methods
			alias :__class :class
			def class # :nodoc:
				return __class.mockedClass
			end
			undef_method :type
			alias_method :type, :class

			# Fake instance_of?, kind_of?, and is_a? with the mocked class
			def instance_of?( klass ) # :nodoc:
				self.class == klass
			end
			def kind_of?( klass ) # :nodoc:
				self.class <= klass
			end
			alias_method :is_a?, :kind_of?


			#########################################################
			###	S E T U P   M E T H O D S
			#########################################################

			### Set the return value for one or more methods. The <tt>hash</tt>
			### should contain one or more key/value pairs, the key of which is
			### the symbol which corresponds to the method being configured, and
			### the value which is a specification of the value to be
			### returned. More complex returns can be configured with one the
			### following types of values:
			### 
			### [<tt>Method</tt> or <tt>Proc</tt>]
			###    A <tt>Method</tt> or <tt>Proc</tt> object will be called with
			###    the arguments given to the method, and whatever it returns
			###    will be used as the return value.
			### [<tt>Array</tt>]
			###    The first value in the <tt>Array</tt> will be rotated to the
			###    end of the Array and returned.
			### [<tt>Hash</tt>]
			###    The Array of method arguments will be used as a key, and
			###    whatever the corresponding value in the given Hash is will be
			###    returned.
			###
			### Any other value will be returned as-is. To return one of the
			### above types of objects literally, just wrap it in an Array like
			### so:
			###
			###		# Return a literal Proc without calling it:
			###		mockObj.setReturnValues( :meth => [myProc] )
			###
			###		# Return a literal Array:
			###		mockObj.setReturnValues( :meth => [["an", "array", "of", "stuff"]] )
			def setReturnValues( hash )
				@returnValues.update hash
			end
			alias_method :__setReturnValues, :setReturnValues
			alias_method :set_return_values, :setReturnValues


			### Set up an expected method call order and argument specification
			### to be checked when #verify is called to the methods specified by
			### the given <tt>symbols</tt>.
			def setCallOrder( *symbols )
				@callOrder = symbols
			end
			alias_method :__setCallOrder, :setCallOrder
			alias_method :set_call_order, :setCallOrder


			### Set the strict call order flag. When #verify is called, the
			### methods specified in calls to #setCallOrder will be checked
			### against the actual methods that were called on the object.  If
			### this flag is set to <tt>true</tt>, any deviation (missing,
			### misordered, or extra calls) results in a failed assertion. If it
			### is not set, other method calls may be interspersed between the
			### calls specified without effect, but a missing or misordered
			### method still fails.
			def strictCallOrder=( flag )
				@strictCallOrder = true if flag
			end
			alias_method :__strictCallOrder=, :strictCallOrder=
			alias_method :strict_call_order=, :strictCallOrder=


			### Returns true if strict call order checking is enabled.
			def strictCallOrder?
				@strictCallOrder
			end
			alias_method :__strictCallOrder?, :strictCallOrder?
			alias_method :strict_call_order?, :strictCallOrder? 


			#########################################################
			###	T E S T I N G   M E T H O D S
			#########################################################

			### Returns an array of Strings describing, in cronological order,
			### what method calls were registered with the object.
			def callTrace
				return [] unless @activated
				@calls.collect {|call|
					"%s( %s ) at %0.5f seconds from %s" % [
						call[:method].to_s,
						call[:args].collect {|arg| arg.inspect}.join(","),
						call[:time] - @activated,
						call[:caller][0]
					]
				}
			end
			alias_method :__callTrace, :callTrace
			alias_method :call_trace, :callTrace


			### Returns an array of Strings describing, in cronological order,
			### what method calls were registered with the object along with a
			### full stacktrace for each call.
			def fullCallTrace
				return [] unless @activated
				@calls.collect {|call|
					"%s( %s ) at %0.5f seconds. Called from %s\n\t%s" % [
						call[:method].to_s,
						call[:args].collect {|arg| arg.inspect}.join(","),
						call[:time] - @activated,
						call[:caller][0],
						call[:caller][1..-1].join("\n\t"),
					]
				}
			end
			alias_method :__fullCallTrace, :fullCallTrace
			alias_method :full_call_trace, :fullCallTrace


			### Turn on call registration -- begin testing.
			def activate
				raise "Already activated!" if @activated
				self.__clear
				@activated = Time::now
			end
			alias_method :__activate, :activate


			### Verify the registered required methods were called with the
			### specified args
			def verify
				raise "Cannot verify a mock object that has never been "\
					"activated." unless @activated
				return true if @callOrder.empty?

				actualCallOrder = @calls.collect {|call| call[:method]}
				diff = Diff::diff( @callOrder, actualCallOrder )

				# In strict mode, any differences are failures
				if @strictCallOrder
					msg = "{Message}"
					assert_block( msg ) {
						unless diff.empty?
							msg.replace __makeCallOrderFailMsg(*diff[0])
						end
						diff.empty?
					}

				# In non-strict mode, only methods missing (:-) from the call
				# order are failures.
				else
					msg = "{Message}"
					assert_block( msg ) {
						missingDiff = diff.find {|d| d[0] == :-}
						unless missingDiff.nil?
							msg.replace __makeCallOrderFailMsg( *missingDiff )
						end
						missingDiff.nil?
					}
				end
			end
			alias_method :__verify, :verify


			### Deactivate the object without doing call order checks and clear
			### the call list, but keep its configuration.
			def clear
				@calls.clear
				@activated = nil
			end
			alias_method :__clear, :clear
			

			### Clear the call list and call order, unset any return values, and
			### deactivate the object without checking for conformance to the
			### call order.
			def reset
				self.__clear
				@callOrder.clear
				@returnValues.clear
			end
			alias_method :__reset, :reset


			#########
			protected
			#########

			### Register a call to the faked method designated by <tt>sym</tt>
			### if the object is activated, and return a value as configured by
			### #setReturnValues given the specified <tt>args</tt>.
			def __mockRegisterCall( sym, *args, &block )
				if @activated
					@calls.push({
						:method		=> sym,
						:args		=> args,
						:time		=> Time::now,
						:caller		=> caller(2),
					})
				end

				rval = @returnValues[ sym ]
				rval_or_lambda = case rval
				when Array
					rval.push( rval.shift )[-1]
				when Hash
					rval[ args ]
				else
					rval
				end
				case rval_or_lambda
				when Method, Proc
					return rval_or_lambda.call( *args, &block )
				else
					return rval_or_lambda
				end
			end
			alias_method :__mock_register_call, :__mockRegisterCall


			### Build and return an error message for a call-order verification
			### failure. The expected arguments are those returned in an element
			### of the Array that is returned from Diff::diff.
			def __makeCallOrderFailMsg( action, position, elements )
				case action

				# "Extra" method/s
				when :+
					extraCall = @calls[ position ]
					return "Call order assertion failed: Unexpected method %s "\
						"called from %s at %0.5f" %
						   [ extraCall[:method].inspect,
						     extraCall[:caller][0],
							 extraCall[:time] - @activated ]

				when :-
					# If there is a call in the position specified, it was a
					# misordered or extra call. If not, there was a missing
					# call.
					missingCall = @callOrder[ position ]
					if extraCall = @calls[ position ]
						return "Call order assertion failed: Expected call to %s, "\
							   "but got call to %s from %s at %0.5f instead" %
							   [ missingCall.inspect,
								 extraCall[:method].inspect,
								 extraCall[:caller][0],
								 extraCall[:time] - @activated ]
					else
						return "Call order assertion failed: Missing call to %s." %
							missingCall.inspect
					end

				else
					return "Unknown diff action '#{action.inspect}'"
				end
			end
			alias_method :__make_call_order_fail_msg, :__makeCallOrderFailMsg


		end

		
		### Factory method for creating semi-functional mock objects given the
		### class which is to be mocked. It looks like a constant for purposes
		### of syntactic sugar.
		def self::MockObject( klass )
			mockup = Class::new( Mockup )
			mockup.instance_eval do @mockedClass = klass end

			### Provide an accessor to class instance var that holds the class
			### object we're faking
			class << mockup

				# The actual class being mocked
				attr_reader :mockedClass

				### Propagate the mocked class ivar to derivatives so it can be
				### called like:
				###   class MockFoo < Test::Unit::MockObject( RealClass )
				def inherited( subclass )
					mc = self.mockedClass
					subclass.instance_eval do @mockedClass = mc end
				end
			end
			
			# Build method definitions for all the mocked class's instance
			# methods, as well as those given to it by its superclasses, since
			# we're not really inheriting from it.
			imethods = klass.instance_methods(true).collect {|name|
				next if name =~ UnmockedMethods

				# Figure out the argument list
				argCount = klass.instance_method( name ).arity
				optionalArgs = false

				if argCount < 0
					optionalArgs = true
					argCount = (argCount+1).abs
				end
				
				args = []
				argCount.times do |n| args << "arg#{n+1}" end
				args << "*optionalArgs" if optionalArgs

				# Build a method definition. Some methods need special
				# declarations.
				case name.intern
				when :initialize
					"def initialize( %s ) ; super ; end" % args.join(',')

				else
					"def %s( %s ) ; self.__mockRegisterCall(%s) ; end" %
						[ name, args.join(','), [":#{name}", *args].join(',') ]
				end
			}

			# Now add the instance methods to the mockup class
			mockup.class_eval imethods.join( "\n" )
			return mockup
		end

	end # module Unit
end # module Test


