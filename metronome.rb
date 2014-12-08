$:.unshift File.expand_path '../../../lib', __FILE__

require 'angelo'
require 'angelo/mustermann'
require 'fluent-logger'
require 'elasticsearch'
require_relative 'metrics'


class Metronome < Angelo::Base
    include Angelo::Mustermann
    include Metrics

    log_level = Logger::ERROR
    log = Fluent::Logger::FluentLogger.new('metronome', :host=>'localhost', :port=>24224)

    get '/tocks/:id' do
      begin
        metrics("id" => params[:id]).to_json
      rescue Exception => e
        puts "#{e.message} + #{e.backtrace}" 
      end
    end

    post '/tick' do
      stats = {item_id: params[:id]}
      stats.merge!(request.headers)
      stats.merge!(params)
      log.post("access", stats)
      stats.to_json
    end

end

Metronome.run!
