module Moob
class SunILom < BaseLom
  @name = 'Sun Integrated Lights Out Manager'

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'root'
    @password ||= 'changeme'
  end

  def authenticate
    auth = @session.post 'iPages/loginProcessor.asp', {
      'username' => @username,
      'password' => @password
    }

    raise ResponseError.new auth unless auth.status == 200

    if auth.body =~ /\/iPages\/i_login.asp\?msg=([^"])+"/
      error = "code #{$1}"
      error_page = @session.get "iPages/i_login.asp?msg=#{$1}"
      if error_page.body =~ /<div class="AlrtErrTxt">(.*?)<\/div>/
        error = "\"#{$1.gsub /<[^>]+>/, ''}\""
      end

      raise "Auth failed (#{error})"
    end

    auth.body =~ /SetWebSessionString\("([^"]+)","([^"]+)"\);/
    raise "Couldn't find session cookie in \"#{auth.body}\"" unless $&

    @cookie = "#{$1}=#{$2}; langsetting=EN"
    return self
  end

  action :jnlp, 'Remote control'
  def jnlp
    viewer = @session.get 'cgi-bin/jnlpgenerator-8', { 'Cookie' => @cookie }
    raise ResponseError.new viewer unless viewer.status == 200

    return viewer.body
  end

  def detect
    begin
      home = @session.get 'iPages/i_login.asp'
      home.body =~ /Sun\(TM\) Sun Integrated Lights Out Manager/
    rescue
      false
    end
  end
end
end
