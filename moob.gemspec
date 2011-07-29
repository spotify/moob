# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'moob'

Gem::Specification.new do |s|
    s.name        = 'moob'
    s.version     = Moob::VERSION.join '.'
    s.platform    = Gem::Platform::RUBY
    s.authors     = ['Pierre Carrier']
    s.email       = ['pierre@gcarrier.fr']
    s.homepage    = "http://github.com/pcarrier/moob"
    s.summary     = 'Manage Out-Of-Band!'
    s.description = 'Control systems using Web-based out-of-band managers without a browser'
    s.license     = 'Public-domain-like'

    s.required_rubygems_version = '>= 1.2.0'
    s.rubyforge_project         = 'moob'

    s.add_dependency 'patron', '~> 0.4.14'

    s.files        = Dir.glob("{bin,lib}/**/*") + %w(COPYING)
    s.executables  = ['moob']
    s.require_path = 'lib'
end
