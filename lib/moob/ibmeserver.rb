module Moob
class IbmEServer < BaseLom
    @name = 'IBM eServer Remote Supervisor Adapter'

    def initialize hostname, options = {}
        super hostname, options
        @username ||= 'USERID'
        @password ||= 'PASSW0RD'
    end

    def authenticate
        auth = @session.post 'private/check_userlogin', {
            'userid' => @username,
            'passwd' => @password
        }

        raise ResponseError.new auth unless auth.status == 200
        raise Exception.new "Auth failed" unless auth.body =~ /\/private\/welcome.ssi/

        init = @session.post 'private/start_menus', {
          'JUNK' => '1',
          'TIMEOUT' => '05'
        }
        raise ResponseError.new init unless init.status == 200

        return self
    end

    action :infos, 'Vital Product Data'
    def infos
      page = @session.get 'private/vpd.ssi'
      raise ResponseError.new page unless page.status == 200

      infos = {}

      infos[:macs] = Hash[
        page.body.scan(/<TR><TD[^>]*>MAC ([^<:]*):<\/TD><TD[^>]>([^<]*)<\/TD><\/TR>/)
      ]

      infos[:type]   = grab page, 'Machine type'
      infos[:model]  = grab page, 'Machine model'
      infos[:serial] = grab page, 'Serial number'
      infos[:uuid]   = grab page, 'UUID'

      return JSON.pretty_generate infos
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

    private
    def grab page, name
      if page =~ /<TR><TD[^>]*>#{name}:<\/TD><TD[^>]*>([^<]*)<\/TD><\/TR>/
        return $1
      end
    end
end
end
