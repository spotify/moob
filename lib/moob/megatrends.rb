class Moob::Megatrends < Moob::BaseLom
    @@name = 'American Megatrends'

    def initialize hostname, options = {}
        super hostname, options
        @username ||= 'root'
        @password ||= 'superuser'
        begin
            @ip = Socket.getaddrinfo(hostname, nil)[0][3]
        rescue
            raise Exception.new "Couldn't resolve \"#{hostname}\""
        end
        @session.base_url = "https://#{@ip}/"
    end

    def authenticate
        auth = @session.post 'rpc/WEBSES/create.asp',
            { 'WEBVAR_USERNAME' => @username, 'WEBVAR_PASSWORD' => @password }

        raise ResponseError.new auth unless auth.status == 200

        auth.body =~ /'SESSION_COOKIE' *: *'([^']+)'/
        raise Exception.new "Couldn't find auth cookie in \"#{auth.body}\"" unless $&

        @cookie = "test=1; path=/; SessionCookie=#{$1}"
        return self
    end

    def jnlp
        viewer = @session.get 'Java/jviewer.jnlp', { 'Cookie' => @cookie }
        raise ResponseError.new viewer unless viewer.status == 200

        return desecurize_jnlp viewer.body
    end

    def detect
        begin
            home = @session.get 'page/login.html'
            home.body =~ /\.\.\/res\/banner_right.png/
        rescue
            false
        end
    end
end
