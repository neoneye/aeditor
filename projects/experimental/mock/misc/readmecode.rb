#!/usr/bin/ruby -w

$LOAD_PATH.unshift ".", ".."

require File::join( File::dirname(File::dirname( __FILE__ )), 'utils.rb' )

begin
	require 'mock'
rescue LoadError
	require 'test/unit/mock'
end
require 'socket'
require 'test/unit'

# This is just a test to make sure the code in the README works as advertised.

class MockTestExperiment < Test::Unit::TestCase

	def setup
		# Create the mock object
		@mockSocket = Test::Unit::MockObject( TCPSocket ).new

		# Make the #addr method return three cycling values (which will be repeated
		# when it reaches the end
		@mockSocket.setReturnValues( :addr => [
			["AF_INET", 23, "localhost", "127.0.0.1"],
			["AF_INET", 80, "slashdot.org", "66.35.250.150"],
			["AF_INET", 2401, "helium.ruby-lang.org", "210.251.121.214"],
		  ] )

		# Make the #write and #read methods call a Proc and a Method, respectively
		@mockSocket.setReturnValues( :write => Proc::new {|str| str.length},
									 :read => method(:fakeRead) )

		# Set up the #getsockopt method to return a value based on the arguments
		# given:
		@mockSocket.setReturnValues( :getsockopt => {
			[Socket::SOL_TCP,    Socket::TCP_NODELAY]	=> [0].pack("i_"),
			[Socket::SOL_SOCKET, Socket::SO_REUSEADDR] => [1].pack("i_"),
		  } )

		@mockSocket.setCallOrder( :addr, :getsockopt, :write, :read, :write, :read )
		@mockSocket.strictCallOrder = true
	end
	alias :set_up :setup

	def teardown
		@mockSocket = nil
	end
	alias :tear_down :teardown


	# A method to fake reading from the socket.
	def fakeRead( len )
		return "x" * len
	end

	# This should pass
	def test_correctorder
		@mockSocket.activate

		# Call the methods in the correct order
		assert_nothing_raised {
			@mockSocket.addr
			@mockSocket.getsockopt( Socket::SOL_TCP, Socket::TCP_NODELAY )
			@mockSocket.write( "foo" )
			@mockSocket.read( 1024 )
			@mockSocket.write( "bar" )
			@mockSocket.read( 4096 )
		}

		if $DEBUG
			puts "Call trace:\n    " + @mockSocket.callTrace.join("\n    ")
		end

		# Check method call order on the mocked socket
		@mockSocket.verify
	end

	# This should fail with an incorrect order message
	def test_incorrectorder
		@mockSocket.activate

		# Call the methods in the correct order
		assert_nothing_raised {
			@mockSocket.addr
			@mockSocket.getsockopt( Socket::SOL_TCP, Socket::TCP_NODELAY )
			@mockSocket.read( 1024 )
			@mockSocket.write( "foo" )
			@mockSocket.write( "bar" )
			@mockSocket.read( 4096 )
		}

		if $DEBUG
			puts "Call trace:\n    " + @mockSocket.callTrace.join("\n    ")
		end

		# Check method call order on the mocked socket
		@mockSocket.verify
	end

	# This should fail with a 'missing' message
	def test_missingcall
		@mockSocket.activate

		# Call the methods in the correct order
		assert_nothing_raised {
			@mockSocket.addr
			@mockSocket.getsockopt( Socket::SOL_TCP, Socket::TCP_NODELAY )
			@mockSocket.write( "foo" )
			@mockSocket.read( 1024 )
			@mockSocket.write( "bar" )
		}

		if $DEBUG
			puts "Call trace:\n    " + @mockSocket.callTrace.join("\n    ")
		end

		# Check method call order on the mocked socket
		@mockSocket.verify
	end

end


