# frozen_string_literal: true
require 'net/http'
require 'uri'

class JsonWebToken
  def self.verify(token, kid)
    JWT.decode(token, kid,
               true, # Verify the signature of this token
               algorithm: 'RS256',
               iss: "#{Rails.application.credentials[Rails.env.to_sym][:auth0_tenant_url]}/",
               verify_iss: true,
               aud: Rails.application.credentials[Rails.env.to_sym][:auth0_api_audience],
               verify_aud: true) do |header|
      jwks_hash[header['kid']]
    end
  end

  # Returns [header, payload]
  def self.parse_and_decode(token)
    segments = token.split('.')
    {
      header:  JWT::JSON.parse(JWT::Base64.url_decode(segments[0])),
      payload: JWT::JSON.parse(JWT::Base64.url_decode(segments[1]))
    }
  rescue ::JSON::ParserError
    raise JWT::DecodeError, 'Invalid token encoding'
  end

  def self.jwks_hash
    jwks_raw = Net::HTTP.get URI("#{Rails.application.credentials[Rails.env.to_sym][:auth0_tenant_url]}/.well-known/jwks.json")
    jwks_keys = Array(JSON.parse(jwks_raw)['keys'])
    Hash[
      jwks_keys
      .map do |k|
        [
          k['kid'],
          OpenSSL::X509::Certificate.new(
            Base64.decode64(k['x5c'].first)
          ).public_key
        ]
      end
    ]
  end
end
