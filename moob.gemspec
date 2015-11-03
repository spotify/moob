# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'moob/version'

Gem::Specification.new do |s|
  s.name        = 'moob'
  if ENV['TRAVIS_TAG'] == 'pre'
    s.version     = "#{Moob::VERSION.join '.'}.pre.#{ENV['TRAVIS_BUILD_NUMBER']}"
  else
    s.version     = Moob::VERSION.join '.'
  end
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nathan Ferch']
  s.email       = ['nf@spotify.com']
  s.homepage    = "https://github.com/spotify/moob"
  s.summary     = 'Manage Out-Of-Band!'
  s.description = 'Control systems using Web-based out-of-band managers without a browser'
  s.license     = 'ISC'

  s.required_rubygems_version = '>= 1.2.0'
  s.rubyforge_project         = 'moob'

  s.add_runtime_dependency 'patron', '~> 0.4', '>= 0.4.14'
  s.add_runtime_dependency 'json', '~> 1.5', '>= 1.5.3'
  s.add_runtime_dependency 'nokogiri'

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(COPYING)
  s.executables  = ['moob']
  s.require_path = 'lib'
end
