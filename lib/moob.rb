require 'socket'
require 'cgi'
require 'patron'

module Moob
    VERSION = [0,1,1]

    autoload :BaseLom,    'moob/baselom.rb'
    autoload :Idrac6,     'moob/idrac6.rb'
    autoload :Megatrends, 'moob/megatrends.rb'
    autoload :SunILom,    'moob/sunilom.rb'

    TYPES = {
        :idrac6     => Idrac6,
        :megatrends => Megatrends,
        :sun        => SunILom
    }

    class ResponseError < Exception
        def initialize response
            @response = response
        end
        def to_s
            "#{@response.url} failed (status #{@response.status})"
        end
    end

    def self.start_jnlp type, hostname, options = {}
        lom = TYPES[type].new hostname, options
        jnlp = lom.authenticate.jnlp

        unless jnlp[/<\/jnlp>/]
            raise RuntimeError.new "Invalid JNLP file (\"#{jnlp}\")"
        end

        filepath = "/tmp/#{hostname}.jnlp"
        File.open filepath, 'w' do |f|
            f.write jnlp
        end

        system "javaws #{filepath}"
    end
end
