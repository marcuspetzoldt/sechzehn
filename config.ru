# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require "rack-rewrite"

ENV['RACK_ENV'] ||= 'development'

#if ENV['RACK_ENV'] == 'development'
#  ENV['SITE_URL'] = 'spiele.sechzehn:3000'
#else
#  ENV['SITE_URL'] = 'spiele.sechzehn.org'
#end

unless ENV['RACK_ENV'] == 'development'
  use Rack::Rewrite do
    r301 %r{.*}, "http://spiele.sechzehn.org$&", :if => Proc.new { |rack_env|
    !(rack_env['SERVER_NAME'].start_with?('spiele'))}

    r301 %r{^(.+)/$}, '$1'
  end
end

run Rails.application
