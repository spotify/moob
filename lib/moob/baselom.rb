require 'socket'
require 'cgi'
require 'patron'
require 'json'
require 'set'

class Moob::BaseLom
  @name = "Unknown"

  def initialize hostname, options = {}
    @hostname = hostname
    @transport = options[:transport] or 'https'
    @username = options[:username]
    @password = options[:password]
    @params = options[:params]

    @session  = Patron::Session.new
    @session.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; '\
      'Intel Mac OS X 10.7; rv:5.0.1) Gecko/20100101 Firefox/5.0.1'
    @session.base_url = "#{@transport}://#{hostname}/"
    @session.connect_timeout = 30
    @session.timeout = 30
    @session.insecure = true
    @session.default_response_charset = 'ISO-8859-1'
  end

  def logout
  end

  attr_reader :hostname, :username

  def detect
    false
  end

  def self.name
    @name
  end

  def self.actions
    @actions
  end

  def self.action sym, descr
    @actions ||= []
    @actions << [sym, descr]
  end
end
