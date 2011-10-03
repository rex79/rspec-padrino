require 'sinatra/base'
require 'padrino-core'
module RSpec::Padrino::Matchers
  module RoutingMatchers
    last_params = nil
    last_name = nil
    Padrino::Application.class_eval do
      before do
        last_params = params
        last_name = request.route_obj.named rescue nil
      end
    end

    extend RSpec::Matchers::DSL

    matcher :route_to do |*expected|
      expected_routes = nil

      match do |verb_to_path_map|
        expected_names = expected.select{|v| Symbol === v }
        expected_params = expected.select{|v| Hash === v }.first || {}
        expected_routes = expected_names.dup.tap{|exp| exp << expected_params.symbolize_keys }
        path, query = *verb_to_path_map.values.first.split('?')
        query = Rack::Utils::parse_query(query)
        method = verb_to_path_map.keys.first
        begin
          Padrino.application.call(Rack::MockRequest.env_for(verb_to_path_map.values.first, :method => method.to_s.upcase))
        rescue
        end
        last_name == expected_names.join("_").to_sym &&
          last_params.symbolize_keys == expected_params.symbolize_keys
      end

      failure_message_for_should do |actual|
        last_names = last_name.to_s.split("_").map(&:to_sym)
        last_names << last_params.symbolize_keys
        "expected #{actual.inspect} to route to #{expected_routes.inspect}, got #{last_names.inspect}"
      end

      failure_message_for_should_not do |actual|
        last_names = last_name.to_s.split("_").map(&:to_sym)
        last_names << last_params.symbolize_keys
        "expected #{actual.inspect} not to route to #{expected.inspect}, got #{last_names.inspect}"
      end
    end

    matcher :be_routable do
      match do |verb_to_path_map|
        begin
          # compile Padrino's routing information
          Padrino.application.call(Rack::MockRequest.env_for("/"))
        end
        path = verb_to_path_map.values.first
        method = verb_to_path_map.keys.first.to_s.upcase
        @routed_to = Padrino.mounted_apps.map(&:app_obj).
          map{|a| a.router.recognize(Rack::MockRequest.env_for(path, :method => method))}.first
      end

      failure_message_for_should_not do |path|
        "expected #{path.inspect} not to be routable, but it routes to #{@routed_to.inspect}"
      end
    end
  end
end
