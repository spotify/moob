module Moob
class Idrac6 < BaseLom
    @name = 'Dell iDrac 6'

    INFO_FIELDS = %w{
        sysDesc
        biosVer
        svcTag
        expSvcCode
        hostName
        osName
        osVersion
        sysRev
        LCCfwVersion
        recoveryAction
        initCountdown
        presentCountdown
        datetime
        fwVersion
        fwUpdated
        hwVersion
        macAddr
        v4Enabled
        v4IPAddr
        v4Gateway
        v4NetMask
        v4DHCPEnabled
        v4DHCPServers
        v4DNS1
        v4DNS2
        v6Enabled
        v6Addr
        v6Gateway
        v6DHCPEnabled
        v6LinkLocal
        v6Prefix
        v6SiteLocal
        v6SiteLocal3
        v6SiteLocal4
        v6SiteLocal5
        v6SiteLocal6
        v6SiteLocal7
        v6SiteLocal8
        v6SiteLocal9
        v6SiteLocal10
        v6SiteLocal11
        v6SiteLocal12
        v6SiteLocal13
        v6SiteLocal14
        v6SiteLocal15
        racName
        v6DHCPServers
        v6DNS1
        v6DNS2
        NicEtherMac1
        NicEtherMac2
        NicEtherMac3
        NicEtherMac4
        NiciSCSIMac1
        NiciSCSIMac2
        NiciSCSIMac3
        NiciSCSIMac4
        NicEtherVMac1
        NicEtherVMac2
        NicEtherVMac3
        NicEtherVMac4
    }

    def initialize hostname, options = {}
        super hostname, options
        @username ||= 'root'
        @password ||= 'calvin'
    end

    def authenticate
        @session.handle_cookies nil
        start = @session.get 'start.html'
        raise ResponseError.new start unless start.status == 200

        auth = @session.post 'data/login',
            "user=#{@username}&password=#{@password}"
        raise ResponseError.new auth unless auth.status == 200

        auth.body =~ /<authResult>([^<]+)<\/authResult>/
        raise Exception.new 'Cannot find auth result' unless $&
        raise Exception.new "Auth failed with: \"#{auth.body}\"" unless $1 == "0"
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
            home.body =~ /Integrated Dell Remote Access Controller 6/
        rescue
            false
        end
    end

    action :jnlp, 'Remote control'
    def jnlp
        idx = @session.get 'index.html'
        raise ResponseError.new idx unless idx.status == 200

        idx.body =~ /var DnsName += +"([^"]+)"/
        raise Exception.new "Couldn't find the DNS name" unless $&
        dns_name = $1

        idx.body =~ /var sysNameStr += +"([^"]+)"/
        raise Exception.new "Couldn't find the system name" unless $&
        sys_name = $1 # eg PowerEdge R610

        # eg escaped "idrac-A1BCD2E, PowerEdge R610, User:root"
        title = CGI::escape "#{dns_name}, #{sys_name}, User:#{@username}"

        viewer = @session.get "viewer.jnlp(#{@hostname}@0@#{title}@#{Time.now.to_i * 1000})"
        raise ResponseError.new viewer unless viewer.status == 200

        return viewer.body
    end

    def power_action action
        req = @session.post "data?set=pwState:#{action}", {}
        raise ResponseError.new req unless req.status == 200
        raise Exception.new 'The answer looks wrong' unless req.body =~ /<status>ok<\/status>/
        return nil
    end

    action :poff,    'Power Off System'
    action :pon,     'Power On System'
    action :pcycle,  'Power Cycle System (cold boot)'
    action :reboot,  'Reset System (warm boot)'
    action :nmi,     'NMI (Non-Masking Interrupt)'
    action :shudown, 'Graceful Shutdown'

    def poff;     power_action 0; end
    def pon;      power_action 1; end
    def pcycle;   power_action 2; end
    def reboot;   power_action 3; end
    def nmi;      power_action 4; end
    def shutdown; power_action 5; end

    def get_infos keys
        infos = @session.post "data?get=#{keys.join(',')}", {}

        raise ResponseError.new infos unless infos.status == 200
        raise Exception.new "The status isn't OK" unless infos.body =~ /<status>ok<\/status>/

        return Hash[keys.collect do |k|
            if infos.body =~ /<#{k}>(.*?)<\/#{k}>/
                [k, $1]
            else
                [k, nil]
            end
        end]
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
        return get_infos(INFO_FIELDS).collect do |k,v|
            "#{k}: #{v}"
        end.join "\n"
    end
end
end
