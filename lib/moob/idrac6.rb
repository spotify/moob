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

        result_match = auth.body.match /<authResult>([^<]+)<\/authResult>/
        raise Exception.new 'Cannot find auth result' unless result_match
        result_code = result_match[1]
        unless result_code == "0"
            raise Exception.new "Auth failed with: \"#{auth.body}\""
        end
        return self
    end

    def jnlp
        idx = @session.get 'index.html'
        raise ResponseError.new idx unless idx.status == 200

        name_match = idx.body.match /var DnsName += +"([^"]+)"/
        raise Exception.new 'Couldn\'t find the DNS name' unless name_match
        dns_name = name_match[1]

        sys_match = idx.body.match /var sysNameStr += +"([^"]+)"/
        raise Exception.new 'Couldn\'t find the system name' unless name_match
        sys_name = sys_match[1] # eg PowerEdge R610

        # eg escaped "idrac-D4MHZ4J, PowerEdge R610, User:root"
        title = CGI::escape "#{dns_name}, #{sys_name}, User:#{@username}"
        path = "viewer.jnlp(#{@hostname}@0@#{title}@#{Time.now.to_i * 1000})"

        viewer = @session.get path
        raise ResponseError.new viewer unless viewer.status == 200

        return desecurize_jnlp viewer.body
    end
end