module Moob
  VERSION = [0,3,8]

  class ResponseError < Exception
    def initialize response
      @response = response
    end
    def to_s
      "#{@response.url} failed (status #{@response.status})"
    end
  end

  autoload :BaseLom,    'moob/baselom.rb'
  autoload :Idrac6,     'moob/idrac6.rb'
  autoload :Idrac7,     'moob/idrac7.rb'
  autoload :Megatrends, 'moob/megatrends.rb'
  autoload :SunILom,    'moob/sunilom.rb'
  autoload :IbmEServer, 'moob/ibmeserver.rb'

  TYPES = {
    :idrac6     => Idrac6,
    :idrac7     => Idrac7,
    :megatrends => Megatrends,
    :sun        => SunILom,
    :ibm        => IbmEServer
  }

  AUTODETECT_ORDER = [ :idrac7, :idrac6, :megatrends, :sun, :ibm ]

  def self.lom type, hostname, options = {}
    case type
    when :auto
      AUTODETECT_ORDER.each do |sym|
        Moob.inform "Trying type #{sym}..."
        lom = TYPES[sym].new hostname, options
        if lom.detect
          Moob.inform "Type #{sym} detected."
          return lom
        end
        false
      end
      raise 'Couldn\'t detect a known LOM type'
    else
      raise "Type #{type} unknown" unless TYPES[type]
      return TYPES[type].new hostname, options
    end
  end

  def self.start_jnlp lom
    jnlp = lom.jnlp

    unless jnlp[/<\/jnlp>/]
      raise "Invalid JNLP file (\"#{jnlp}\")"
    end

    filepath = "/tmp/#{lom.hostname}_#{Time.now.to_i}.jnlp"
    File.open filepath, 'w' do |f|
      f.write jnlp
    end

    raise 'javaws failed' unless system "javaws -wait #{filepath}"
  end

  def self.inform msg
    $stderr.puts "\033[36m#{msg}\033[0m" if $VERBOSE
  end

  def self.warn msg
    $stderr.puts "\033[36m#{msg}\033[0m"
  end
end
