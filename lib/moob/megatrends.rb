module Moob
class Megatrends < BaseLom
    @name = 'American Megatrends'

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

    def detect
        begin
            home = @session.get 'page/login.html'
            home.body =~ /\.\.\/res\/banner_right.png/
        rescue
            false
        end
    end

    action :jnlp
    def jnlp
        viewer = @session.get 'Java/jviewer.jnlp', { 'Cookie' => @cookie }
        raise ResponseError.new viewer unless viewer.status == 200

        return viewer.body
    end

    def power_action action
        req = @session.post 'rpc/hostctl.asp',
            { 'WEBVAR_POWER_CMD' => action },
            { 'Cookie' => @cookie }
        raise ResponseError.new req unless req.status == 200
        unless req.body =~ /WEBVAR_STRUCTNAME_HL_POWERSTATUS/
            raise Exception.new 'The answer looks wrong'
        end
        return nil
    end

    action :power_off
    def power_off;      power_action 0; end
    action :power_on
    def power_on;       power_action 1; end
    action :power_cycle
    def power_cycle;    power_action 2; end
    action :power_reset
    def power_reset;    power_action 3; end
    action :soft_power_off
    def soft_power_off; power_action 5; end

    action :power_status
    def power_status
        status = @session.get 'rpc/hoststatus.asp',
            { 'Cookie' => @cookie }
        raise ResponseError.new status unless status.status == 200
        raise Exception.new unless status.body =~ /'JF_STATE' : (.),/
        case $1
        when '0'
            return :off
        when '1'
            return :on
        end
    end
end
end
