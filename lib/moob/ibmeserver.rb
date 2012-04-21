module Moob
class IbmEServer < BaseLom
  @name = 'IBM eServer Remote Supervisor Adapter'

  def initialize hostname, options = {}
      super hostname, options
      @username ||= 'USERID'
      @password ||= 'PASSW0RD'
  end

  def authenticate
      @session.handle_cookies nil

      home = @session.get ''
      raise ResponseError.new home unless home.status == 200

      auth = @session.post 'private/check_userlogin', {
          'userid' => @username,
          'passwd' => @password
      }
      raise ResponseError.new auth unless auth.status == 200

      init = @session.post 'private/start_menus', {
        'JUNK' => '1',
        'TIMEOUT' => '05'
      }
      raise ResponseError.new init unless init.status == 200

      return self
  end

  action :infos, 'Vital Product Data'
  def infos
    return JSON.pretty_generate get_infos
  end

  def detect
      begin
          home = @session.get 'private/userlogin.ssi'
          home.body =~ /Remote Supervisor Adapter/
      rescue
          false
      end
  end

  def logout
    page = @session.get 'private/logoff'
    raise ResponseError.new page unless page.status == 200
  end

  def get_infos
    page = @session.get 'private/vpd.ssi'
    raise ResponseError.new page unless page.status == 200

    infos = {}

    infos[:macs] = Hash[
      page.body.scan /<TR><TD[^>]*>MAC ([^:]*):<\/TD><TD[^>]*>([^<]*)<\/TD><\/TR>/
    ]

    infos[:type]   = grab page.body, 'Machine type'
    infos[:model]  = grab page.body, 'Machine model'
    infos[:serial] = grab page.body, 'Serial number'
    infos[:uuid]   = grab page.body, 'UUID'
  end

  private
  def grab contents, name
    if contents =~ /<TR><TD[^>]*>#{name}:<\/TD><TD[^>]*>([^<]*)<\/TD><\/TR>/
      return $1
    end
  end
end
end
