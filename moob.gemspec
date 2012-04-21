# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'moob'

Gem::Specification.new do |s|
  s.name        = 'moob'
  s.version     = Moob::VERSION.join '.'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Pierre Carrier']
  s.email       = ['pierre@spotify.com']
  s.homepage    = "https://github.com/spotify/moob"
  s.summary     = 'Manage Out-Of-Band!'
  s.description = 'Control systems using Web-based out-of-band managers without a browser'
  s.license     = 'ISC'

  s.required_rubygems_version = '>= 1.2.0'
  s.rubyforge_project         = 'moob'

  s.add_dependency 'patron', '~> 0.4.14'
  s.add_dependency 'json', '~> 1.5.3'

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(COPYING)
  s.executables  = ['moob']
  s.require_path = 'lib'
end
