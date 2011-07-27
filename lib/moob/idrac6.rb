class Moob::Idrac6 < Moob::BaseLom
    @@name = 'Dell iDrac 6'

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

        return desecurize_jnlp viewer.body
    end
end
