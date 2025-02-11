# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/io/shared_endpoint'

RSpec.shared_context Async::HTTP::Server do
	include_context Async::RSpec::Reactor
	
	let(:protocol) {described_class}
	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', timeout: 0.8, reuse_port: true, protocol: protocol)}
	
	let(:retries) {1}
	
	let(:server) do
		Async::HTTP::Server.for(@bound_endpoint) do |request|
			Protocol::HTTP::Response[200, {}, []]
		end
	end
	
	before do
		# We bind the endpoint before running the server so that we know incoming connections will be accepted:
		@bound_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		
		# I feel a dedicated class might be better than this hack:
		allow(@bound_endpoint).to receive(:protocol).and_return(endpoint.protocol)
		allow(@bound_endpoint).to receive(:scheme).and_return(endpoint.scheme)
		
		@server_task = Async do
			server.run
		end
		
		@client = Async::HTTP::Client.new(endpoint, protocol: endpoint.protocol, retries: retries)
	end
	
	after do
		@client&.close
		@server_task&.stop
		@bound_endpoint&.close
	end
	
	let(:client) {@client}
end
