module Moob
class Pec < BaseLom
  @name = 'Dell PowerEdge C series'

  INFO_FIELDS = %w[
	  asic certificate
	  chassisFLEDStatus chassisILEDStatus chassisName
	  biosVer fwUpdated fwVersion hostname hwVersion
	  ipmiKey ipmiLAN ipmiMinPriv
	  productDescription productName pwState
	  serialOverLanBaud serialOverLanEnabled serialOverLanPriv
	  hostname
	  ifName macAddr autoNeg v4Enabled v4DHCPEnabled v4IPAddr 
	  v4NetMask v4Gateway
  ]

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'root'
    @password ||= 'root'
    @index = nil
  end

  def authenticate
    @session.handle_cookies nil

    login = @session.get 'login.html'

    raise ResponseError.new login unless login.status == 200

    auth = @session.post 'data/login', "user=#{@username}&password=#{@password}"

    raise ResponseError.new auth unless auth.status == 200

    auth.body =~ /<authResult>([^<]+)<\/authResult>/

    raise 'Cannot find auth result' unless $&
    raise "Auth failed with: \"#{auth.body}\"" unless $1 == "0"

    auth.body =~ /<forwardUrl>([^<]+)<\/forwardUrl>/

    raise 'Cannot find the authenticated index url after auth' unless $&

    @indexurl = $1


    Moob.inform "Requesting indexurl of #{@indexurl}"
    @authhash = @indexurl.split('?')[1]

    @index = @session.get @indexurl

    # someone decided it was a good idea to include a ST2 token in every XHR
    # request. We need it for a lot of our features.
    @index.body =~ /var CSRF_TOKEN_2_VALUE = "([0-9a-f]+)";/
    raise ResponseError.new @index unless @index.status == 200
    @st2 = $1

    @session.headers['ST2'] = @st2

    return self
  end

  def logout
    out = @session.get 'data/logout'
    raise ResponseError.new out unless out.status == 200
    return self
  end

  def detect
    begin
      home = @session.get 'login.html'
      home.body =~ /Dell Remote Management Controller/
    rescue
      false
    end
  end

  action :jnlp, 'Remote control'

  def jnlp
    # On PEC LOM CSRF_TOKEN_1 carries the auth token	  
    @index.body =~ /var CSRF_TOKEN_1\s+= \"ST1\" \+ \"=\" \+ "([0-9a-f]+)";/
    @st1 = $1

    viewer = @session.get "viewer.jnlp(#{@hostname}@0@#{Time.now.to_i * 1000})?ST1=#{@st1}"
    raise ResponseError.new viewer unless viewer.status == 200

    return viewer.body
  end

  def power_control action
    req = @session.post "data?set=pwState:#{action}", {}
    raise ResponseError.new req unless req.status == 200
    return nil
  end

  [
    [0, :poff,   'Power Off System'],
    [1, :pon,    'Power On System'],
    [2, :pcycle,   'Power Cycle System (cold boot)'],
    [3, :preset,   'Reset System (warm boot)'],
    [4, :nmi,    'NMI (Non-Masking Interrupt)'],
    [5, :shutdown, 'Graceful Shutdown']
  ].each do |code, name, desc|
    action name, desc
    class_eval %{def #{name}; power_control #{code}; end}
  end

  
  action :pstatus, 'Power status'
  def pstatus
    case get_infos(['pwState'])['pwState']
    when '0'
      return :off
    when '1'
      return :on
    else
      return nil
    end
  end

  action :infos, 'Get system information'
  def infos
    return JSON.pretty_generate get_infos INFO_FIELDS
  end

  def get_infos keys
    infos = @session.post "data?get=#{keys.join(',')}", {}

    raise ResponseError.new infos unless infos.status == 200
    raise "The status isn't OK" unless infos.body =~ /<status>ok<\/status>/

    return Hash[keys.collect do |k|
      if infos.body =~ /<#{k}>(.*?)<\/#{k}>/
        [k, $1]
      else
        [k, nil]
      end
    end]
  end

  action :set_params, 'Set LOM parameters'
  def set_params
    unless @params
      raise "Params are not set!"
    end
    drac_set_params @params
  end

  action :enable_ipmi, 'Enable IPMI over LAN (on LOM port)'
  def enable_ipmi
    drac_set_params({ 'ipmiLAN' => 1 })
  end

  def drac_set_params params
    params.each do |p,v|
      req = @session.post "data?set=#{p}:#{v}", {}
      raise ResponseError.new req unless req.status == 200
    end
    return nil
  end

end
end
