module Moob

class Idrac7 < BaseLom
  @name = 'Dell iDrac 7'

  INFO_FIELDS = %w[
    biosVer svcTag expSvcCode hostName
    osName osVersion sysDesc sysRev datetime initCountdown presentCountdown
    fwVersion fwUpdated LCCfwVersion
    firstBootDevice vmBootOnce
    racName hwVersionmacAddr recoveryAction
    NicEtherMac1  NicEtherMac2  NicEtherMac3  NicEtherMac4
    NiciSCSIMac1  NiciSCSIMac2  NiciSCSIMac3  NiciSCSIMac4
    NicEtherVMac1 NicEtherVMac2 NicEtherVMac3 NicEtherVMac4
    v4Enabled v4IPAddr v4Gateway v4NetMask
    v6Enabled v6Addr   v6Gateway v6Prefix v6LinkLocal
    v4DHCPEnabled v4DHCPServers v4DNS1 v4DNS2
    v6DHCPEnabled v6DHCPServers v6DNS1 v6DNS2
    v6SiteLocal v6SiteLocal3 v6SiteLocal4 v6SiteLocal5 v6SiteLocal6 v6SiteLocal7 v6SiteLocal8
    v6SiteLocal9 v6SiteLocal10 v6SiteLocal11 v6SiteLocal12 v6SiteLocal13 v6SiteLocal14 v6SiteLocal15
    ipmiLAN ipmiMinPriv ipmiKey hostname
  ]

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'root'
    @password ||= 'calvin'
    @index = nil
  end

  def authenticate
    @session.handle_cookies nil
    # Needed for new version of iDrac emb web server to even responde
    @session.headers['Accept-Language'] = 'en-US,en;q=0.8,sv;q=0.6'
    # idrac7 responds with a 404 if the request is sent for html is sent without encoding headers
    @session.headers['Accept-Encoding'] = 'gzip,deflate,sdch'

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

    #1.30.30 (Build 43) introduced a nag to change credentials. bypass it.

    if @indexurl =~ /defaultCred/
      @indexurl.gsub!(/defaultCred/,'index')
      Moob.inform "iDRAC recommends you should change the default credentials!"
    end

    Moob.inform "Requesting indexurl of #{@indexurl}"

    # someone decided it was a good idea to include a ST2 token in every XHR
    # request. We need it for a lot of our features.
    @authhash = @indexurl.split('?')[1]
    @authhash =~ /ST2=([0-9a-f]+)/
    @st2 = $1

    if @st2.nil?
        Moob.inform 'Trying to parse ST2 token from HTML page'

        @index = @session.get @indexurl
        @index.body =~ /var TOKEN_VALUE = "([0-9a-f]+)";/
        raise ResponseError.new @index unless @index.status == 200
        @st2 = $1
    end

    @session.headers['ST2'] = @st2

    return self
  end

  def logout
    if @skiplogout
      Moob.inform 'Skipping logout...'
    else
      out = @session.get 'data/logout'
      raise ResponseError.new out unless out.status == 200
    end
    return self
  end

  def detect
    begin
      home = @session.get 'login.html'
      home.body =~ /(Integrated Dell Remote Access Controller 7)|(iDRAC7)/
    rescue
      false
    end
  end

  action :jnlp, 'Remote control'

  def jnlp
    # Request system name and hostname from data end-point
    req = get_infos ['sysDesc' ,'hostname']

    # eg escaped "idrac-A1BCD2E, PowerEdge R610, User:root"
    title = CGI::escape "#{req['hostname']}, #{req['sysDesc']}, User:#{@username}"

    viewer = @session.get "viewer.jnlp(#{@hostname}@0@#{title}@#{Time.now.to_i * 1000}@#{@authhash})"
    raise ResponseError.new viewer unless viewer.status == 200

    return viewer.body
  end

  def power_control action
    req = @session.post "data?set=pwState:#{action}", {}
    raise ResponseError.new req unless req.status == 200
    return nil
  end

  def boot_on level
    req = @session.post "data?set=vmBootOnce:1,firstBootDevice:#{level}", {}
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

  [
    [0,  :bnone,    'Do not change the next boot'],
    [1,  :bpxe,     'Boot on PXE once'],
    [6,  :bbios,    'Boot on BIOS setup once'],
    [15, :blfloppy, 'Boot on Local Floppy/Primary Removable Media once'],
    [5,  :blcd,     'Boot on Local CD/DVD once'],
    [2,  :blhd,     'Boot on Hard Drive once'],
    [9,  :biscsi,   'Boot on NIC BEV iSCSI once'],
    [7,  :bvfloppy, 'Boot on Virtual Floppy once'],
    [8,  :bvcd,     'Boot on Virtual CD/DVD/ISO once'],
    [16, :blsd,     'Boot on Local SD Card once'],
    [11, :bvflash,  'Boot on vFlash once']
  ].each do |code, name, desc|
    action name, desc
    class_eval %{def #{name}; boot_on #{code}; end}
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
    Moob.inform "Requesting data?get=#{keys.join(',')}"
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

  action :set_params, 'Set iDRAC parameters'
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

  action :show_console_preview, 'Display iDRAC console screenshot'
  action :save_console_preview, 'Save iDRAC console screenshot'

  def fetch_console_preview
    imgfile = Tempfile.new('console_preview')

    refreshreq = @session.get "data?get=consolepreview[auto%20#{Time.now.utc.to_i}]", {}

    raise ResponseError.new req unless refreshreq.status == 200

    req = @session.get_file "capconsole/scapture0.png?#{Time.now.utc.to_i}", imgfile.path

    raise ResponseError.new req unless req.status == 200

    content_type = req.headers['Content-type'] || req.headers['Content-Type']
    raise "Unexpected content type #{content_type}, expected 'image/' prefix" unless content_type =~ /image\//

    return imgfile, req.headers
  end

  action :lomreset, 'Reset LOM'
  def lomreset
    @skiplogout = true
    drac_set_params({ 'iDracReset' => 1 })
  end

end
end
