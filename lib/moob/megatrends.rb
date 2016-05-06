module Moob
class Megatrends < BaseLom
  @name = 'American Megatrends'

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'root'
    @password ||= 'superuser'
    begin
      @ip = Socket.getaddrinfo(hostname, nil)[0][3]
    rescue
      raise "Couldn't resolve \"#{hostname}\""
    end
    @session.base_url = "#{@transport}://#{@ip}/"
  end

  def authenticate
    auth = @session.post 'rpc/WEBSES/create.asp',
      { 'WEBVAR_USERNAME' => @username, 'WEBVAR_PASSWORD' => @password }

    raise ResponseError.new auth unless auth.status == 200

    auth.body =~ /'SESSION_COOKIE' *: *'([^']+)'/
    raise "Couldn't find auth cookie in \"#{auth.body}\"" unless $&

    @cookie = "test=1; path=/; SessionCookie=#{$1}"
    return self
  end

  def detect
    begin
      home = @session.get 'page/login.html'
      home.body =~ /\.\.\/res\/banner_right\.png/
    rescue
      false
    end
  end

  action :jnlp, 'Remote control'
  def jnlp
    @session.ignore_content_length = true
    viewer = @session.get "Java/jviewer.jnlp?EXTRNIP=#{@ip}&JNLPSTR=JViewer", { 'Cookie' => @cookie }
    raise ResponseError.new viewer unless viewer.status == 200

    return viewer.body
  end

  def power_action action
    req = @session.post 'rpc/hostctl.asp',
      { 'WEBVAR_POWER_CMD' => action },
      { 'Cookie' => @cookie }
    raise ResponseError.new req unless req.status == 200
    unless req.body =~ /WEBVAR_STRUCTNAME_HL_POWERSTATUS/
      raise 'The answer looks wrong'
    end
    return nil
  end

  action :poff,     'Power Off'
  action :pon,      'Power On'
  action :pcycle,   'Power Cycle'
  action :preset,   'Power Reset'
  action :shutdown, 'Soft Power Off'
  def poff;      power_action 0; end
  def pon;       power_action 1; end
  def pcycle;    power_action 2; end
  def preset;    power_action 3; end
  def soft_poff; power_action 5; end

  action :pstatus, 'Power status'
  def pstatus
    status = @session.get 'rpc/hoststatus.asp',
      { 'Cookie' => @cookie }
    raise ResponseError.new status unless status.status == 200
    raise 'Couldn\'t read the state' unless status.body =~ /'JF_STATE' : (.),/
    case $1
    when '0'
      return :off
    when '1'
      return :on
    end
  end
end
end
