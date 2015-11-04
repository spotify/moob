require 'fileutils'
require 'tempfile'

module Moob

  class ResponseError < Exception
    def initialize response
      @response = response
    end
    def to_s
      "#{@response.url} failed (status #{@response.status})"
    end
  end

  autoload :VERSION,    'moob/version.rb'
  autoload :BaseLom,    'moob/baselom.rb'
  autoload :Idrac6,     'moob/idrac6.rb'
  autoload :Idrac7,     'moob/idrac7.rb'
  autoload :Idrac8,     'moob/idrac8.rb'
  autoload :IdracXml,   'moob/idracxml.rb'
  autoload :Pec,        'moob/pec.rb'
  autoload :Megatrends, 'moob/megatrends.rb'
  autoload :SunILom,    'moob/sunilom.rb'
  autoload :IbmEServer, 'moob/ibmeserver.rb'
  autoload :Supermicro, 'moob/supermicro.rb'

  TYPES = {
    :idrac6     => Idrac6,
    :idrac7     => Idrac7,
    :idrac8     => Idrac8,
    :idracxml   => IdracXml,
    :pec        => Pec,
    :megatrends => Megatrends,
    :sun        => SunILom,
    :ibm        => IbmEServer,
    :supermicro => Supermicro
  }

  AUTODETECT_ORDER = [ :idrac8, :idrac7, :idrac6, :pec, :supermicro, :megatrends, :sun, :ibm ]

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

    tmpfile = Tempfile.new("#{lom.hostname}_#{Time.now.to_i}.jnlp")
    tmpfile.write jnlp
    tmpfile.close

    raise 'javaws failed' unless system "javaws -wait #{tmpfile.path}"
  end

  def self.show_console_preview lom
    imgfile, headers = lom.fetch_console_preview

    if RUBY_PLATFORM =~ /darwin/
      raise 'open failed' unless system "open #{imgfile.path}"
    else
      raise 'see failed' unless system "see #{imgfile.path}"
    end
  end

  def self.save_console_preview lom
    imgfile, headers = lom.fetch_console_preview

    timestamp=Time.parse(headers['Last-modified'] || headers['Last-Modified'])
    fileext=(headers['Content-type'] || headers['Content-Type']).split('/')[1]

    filename="#{lom.hostname}-#{timestamp.utc.iso8601(0)}.#{fileext}"

    FileUtils.cp(imgfile.path, filename)

    return filename
  end

  def self.inform msg
    $stderr.puts "\033[36m#{msg}\033[0m" if $VERBOSE
  end

  def self.warn msg
    $stderr.puts "\033[36m#{msg}\033[0m"
  end
end
