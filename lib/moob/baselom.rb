require 'socket'
require 'cgi'
require 'patron'
require 'set'

class Moob::BaseLom
    @name = "Unknown"

    def initialize hostname, options = {}
        @hostname = hostname
        @username = options[:username]
        @password = options[:password]

        @session  = Patron::Session.new
        @session.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; '\
            'Intel Mac OS X 10.7; rv:5.0.1) Gecko/20100101 Firefox/5.0.1'
        @session.base_url = "https://#{hostname}/"
        @session.connect_timeout = 10_000
        @session.timeout = 10_000
        @session.insecure = true
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
        @actions ||= {}
        @actions[sym] = descr
    end
end
