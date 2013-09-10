module Moob
class Supermicro < BaseLom
  @name = 'Supermicro'

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'ADMIN'
    @password ||= 'ADMIN'
    begin
      @ip = Socket.getaddrinfo(hostname, nil)[0][3]
    rescue
      raise "Couldn't resolve \"#{hostname}\""
    end
    @session.base_url = "#{@transport}://#{@ip}/"
  end

  def authenticate
    @session.handle_cookies nil
    auth = @session.post 'cgi/login.cgi',
      "name=#{@username}&pwd=#{@password}"

    raise ResponseError.new auth unless auth.status == 200
    return self
  end

  def detect
    begin
      home = @session.get '/'
      home.body =~ /META NAME=\"ATEN International Co Ltd\.\"/
    rescue
      false
    end
  end

  def power_action action
    time_s = Time.now.strftime("%a %b %d %Y %H:%M:%S")
    req = @session.get "cgi/ipmi.cgi?POWER_INFO.XML=" + CGI::escape(action) + "&time_stamp=" + CGI::escape(time_s)
    raise ResponseError.new req unless req.status == 200
    unless req.body =~ /POWER_INFO/
      raise 'The answer looks wrong'
    end
    return nil
  end

  action :poff,     'Power Off'
  action :pon,      'Power On'
  action :pcycle,   'Power Cycle'
  action :preset,   'Power Reset'
  action :shutdown, 'Soft Power Off'
  def poff;      power_action "(1,0)"; end
  def pon;       power_action "(1,1)"; end
  def pcycle;    power_action "(1,2)"; end
  def preset;    power_action "(1,3)"; end
  def shutdown; power_action "(1,5)"; end

  action :pstatus, 'Power status'
  def pstatus
    time_s = Time.now.strftime("%a %b %d %Y %H:%M:%S")
    status = @session.get "cgi/ipmi.cgi?POWER_INFO.XML=(0%2C0)&time_stamp=" + CGI::escape(time_s)
    raise ResponseError.new status unless status.status == 200
    raise 'Couldn\'t read the state' unless status.body =~ /POWER STATUS=\"([A-Z]+)\"/
    case $1
    when 'OFF'
      return :off
    when 'ON'
      return :on
    end
  end

end
end
