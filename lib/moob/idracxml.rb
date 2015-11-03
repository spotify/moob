require 'nokogiri'

module Moob
class IdracXml < BaseLom
  @name = 'Dell iDrac XML'

  def initialize hostname, options = {}
    super hostname, options
    @username ||= 'root'
    @password ||= 'calvin'
    @arg = options[:arg]

    discover
  end

  def xml_request method, uri, data
    out = @session.send(method, uri, data)

    raise ResponseError.new out unless out.status == 200

    out_xml = Nokogiri::XML(out.body)
    raise "Cannot parse XML response for request to #{uri}" unless out_xml

    resp_xml = out_xml.xpath("//RESP")
    raise "Cannot find response XML node in response to #{uri}" unless resp_xml

    resp = {}
    resp[:body] = out.body
    resp[:parsed_xml] = {}

    resp_xml.children.each do |n|
      resp[:parsed_xml][n.name] = n.content
    end
    if resp[:parsed_xml].include?('RC')
      resp[:rc] = Integer(resp[:parsed_xml]['RC'])
      if resp[:rc] != 0
        Moob.warn "Return code from #{uri} is #{resp[:rc]}"
      end
    end

    return resp
  end

  def authenticate
    @session.handle_cookies nil
    resp = xml_request 'post', 'cgi-bin/login',
      "<?xml version='1.0'?><LOGIN><REQ><USERNAME>#{@username}</USERNAME><PASSWORD>#{@password}</PASSWORD></REQ></LOGIN>"

    raise "Auth failed with: \"#{resp[:body]}\"" unless resp[:rc] == 0
    raise "Session ID missing from response" unless resp[:parsed_xml].include?('SID')

    @sid = resp[:parsed_xml]['SID']
    @session.headers['Cookie'] = "sid=#{@sid}"
    return self
  end

  def discover
    resp = xml_request 'get', 'cgi-bin/discover', {}

    raise "Unsupported iDRAC" unless resp[:parsed_xml]['ENDPOINTTYPE'] =~ /^iDRAC[7-8]?$/
    raise "Unsupported iDRAC subversion" unless resp[:parsed_xml]['ENDPOINTVER'] == '1.00'
    raise "Unsupported protocol type" unless resp[:parsed_xml]['PROTOCOLTYPE'] == 'HTTPS'
    raise "Unsupported protocol version" unless resp[:parsed_xml]['PROTOCOLVER'] == '2.0'
  end

  def logout
    out = xml_request 'get', 'cgi-bin/logout', {}
    return self
  end

  action :exec, 'Execute a command'
  def exec
    out = xml_request 'post', '/cgi-bin/exec',
      "<?xml version='1.0'?><EXEC><REQ><CMDINPUT>#{@arg}</CMDINPUT><MAXOUTPUTLEN>0x0fff</MAXOUTPUTLEN></REQ></EXEC>"

    puts out[:parsed_xml]['CMDOUTPUT']
    return nil
  end

end
end
