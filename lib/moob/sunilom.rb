class Moob::SunILom < Moob::BaseLom
    @@name = 'Sun Integrated Lights Out Manager'

    def initialize hostname, options = {}
        super hostname, options
        @username ||= 'root'
        @password ||= 'changeme'
    end

    def authenticate
        auth = @session.post 'iPages/loginProcessor.asp', {
            'username' => @username,
            'password' => @password
        }

        raise ResponseError.new auth unless auth.status == 200

        cookie_match = auth.body.match /SetWebSessionString\("([^"]+)","([^"]+)"\);/
        unless cookie_match
            raise Exception.new "Couldn't find session cookie in \"#{auth.body}\""
        end

        @cookie = "#{cookie_match[1]}=#{cookie_match[2]}; langsetting=EN"
        return self
    end

    def jnlp
        viewer = @session.get 'cgi-bin/jnlpgenerator-8', { 'Cookie' => @cookie }
        raise ResponseError.new viewer unless viewer.status == 200

        return viewer.body
    end
end
