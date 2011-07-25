class Moob::Megatrends < Moob::BaseLom
    @@name = 'American Megatrends'

    def initialize hostname, options = {}
        super hostname, options
        @username ||= 'root'
        @password ||= 'superuser'
        begin
            @ip = Socket.getaddrinfo(hostname, nil)[0][2]
        rescue
            raise Exception.new "Couldn't resolve \"#{hostname}\""
        end
        @session.base_url = "https://#{@ip}/"
    end

    def authenticate
        auth = @session.post 'rpc/WEBSES/create.asp',
            { 'WEBVAR_USERNAME' => @username, 'WEBVAR_PASSWORD' => @password }

        raise ResponseError.new auth unless auth.status == 200

        cookie_match = auth.body.match /'SESSION_COOKIE' *: *'([^']+)'/
        unless cookie_match
            raise Exception.new "Couldn't find auth cookie in \"#{auth.body}\""
        end

        @cookie = "test=1; path=/; SessionCookie=#{cookie_match[1]}"
        return self
    end

    def jnlp
        viewer = @session.get 'Java/jviewer.jnlp', { 'Cookie' => @cookie }
        raise ResponseError.new viewer unless viewer.status == 200

        return desecurize_jnlp viewer.body
    end
end
