module Moob
class Idrac6 < BaseLom
    @name = 'Dell iDrac 6'

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
        raise Exception.new 'Couldn\'t find the DNS name' unless $&
        dns_name = $1

        idx.body =~ /var sysNameStr += +"([^"]+)"/
        raise Exception.new 'Couldn\'t find the system name' unless $&
        sys_name = $1 # eg PowerEdge R610

        # eg escaped "idrac-A1BCD2E, PowerEdge R610, User:root"
        title = CGI::escape "#{dns_name}, #{sys_name}, User:#{@username}"

        viewer = @session.get "viewer.jnlp(#{@hostname}@0@#{title}@#{Time.now.to_i * 1000})"
        raise ResponseError.new viewer unless viewer.status == 200

        return viewer.body
    end

    def power_action action
        req = @session.post "date?set=pwState:#{action}"
        raise ResponseError.new req unless req.status == 200
        raise Exception.new 'The answer looks wrong' unless status.body =~ /<status>ok<\/status>/
        return nil
    end

    action :power_off,   'Power Off System'
    action :power_on,    'Power On System'
    action :power_cycle, 'Power Cycle System (cold boot)'
    action :reboot,      'Reset System (warm boot)'
    action :nmi,         'NMI (Non-Masking Interrupt)'
    action :shudown,     'Graceful Shutdown'

    def poff;     power_action 0; end
    def pon;      power_action 1; end
    def pcycle;   power_action 2; end
    def reboot;   power_action 3; end
    def nmi;      power_action 4; end
    def shutdown; power_action 5; end

    action :power_status, 'Power status'
    def power_status
        status = @session.post 'data?get=pwState,',
            { 'Cookie' => @cookie }
        raise ResponseError.new status unless status.status == 200
        raise Exception.new 'The answer looks wrong' unless status.body =~ /<status>ok<\/status>/
        raise Exception.new 'Couldn\'t read the state' unless status.body =~ /<pwState>(.)<\/pwState>/
        case $1
        when '0'
            return :off
        when '1'
            return :on
        end
    end
end
end
