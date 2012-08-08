require "cgi"
require "base64"
require "openssl"
require "digest/sha1"
require "net/http"
require "time"

module Alexa
  class Connection
    attr_accessor :secret_access_key, :access_key_id
    attr_writer :params

    def initialize(credentials = {})
      self.secret_access_key = credentials.fetch(:secret_access_key)
      self.access_key_id     = credentials.fetch(:access_key_id)
    end

    def params
      @params ||= {}
    end

    def get(params = {})
      self.params = params
      encode handle_response(request).body
    end

    def handle_response(response)
      case response.code.to_i
      when 200...300
        response
      when 300...600
        if response.body.nil?
          raise ResponseError.new(nil, response)
        else
          xml = MultiXml.parse(response.body)
          message = xml["Response"]["Errors"]["Error"]["Message"]
          raise ResponseError.new(message, response)
        end
      else
        raise ResponseError.new("Unknown code: #{respnse.code}", response)
      end
    end

    def request
      Net::HTTP.get_response(uri)
    end

    def timestamp
      @timestamp ||= Time::now.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
    end

    def signature
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha256"), secret_access_key, sign)).strip
    end

    def uri
      URI.parse("http://#{Alexa::API_HOST}/?" + query + "&Signature=" + CGI::escape(signature))
    end

    def default_params
      {
        "AWSAccessKeyId"   => access_key_id,
        "SignatureMethod"  => "HmacSHA256",
        "SignatureVersion" => "2",
        "Timestamp"        => timestamp,
        "Version"          => Alexa::API_VERSION
      }
    end

    def sign
      "GET\n" + Alexa::API_HOST + "\n/\n" + query
    end

    def query
      default_params.merge(params).map { |key, value| "#{key}=#{CGI::escape(value.to_s)}" }.sort.join("&")
    end

    def encode(string)
      if "muflon".respond_to?(:force_encoding)
        string.force_encoding(Encoding::UTF_8)
      else
        string
      end
    end
  end
end
