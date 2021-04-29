# retrieve secret from vault

require 'rbconfig'

Puppet::Functions.create_function(:'vault::get_secret') do
  dispatch :get_secret do
    param 'String', :vault_uri
    param 'String', :secret
    param 'String', :field
    param 'Boolean', :kv_v2
    optional_param 'String', :token_path
    optional_param 'Boolean', :token_wrapped
  end

  def get_secret(vault_uri, secret, field, kv_v2, token_path = '', token_wrapped = false)
    uri = URI(vault_uri)
    connection = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    token = ''
    unless token_path == ''
      if token_wrapped
        token = unwrap(token_path, connection)
      else
        begin
          token = File.read(token_path)
        rescue StandardError
          raise Puppet::Error, "Unable to parse token at #{token_path}"
        end
      end
    end

    header = { 'X-Vault-Token' => token }

    request_headers = if kv_v2
                        Net::HTTP::Get.new('/v1/kv/data/' + secret, header)
                      else
                        Net::HTTP::Get.new('/v1/' + secret, header)
                      end

    vault_response = connection.request(request_headers)

    begin
      resolved_secret = if kv_v2
                          JSON.parse(vault_response.body)['data']['data'][field.to_s]
                        else
                          JSON.parse(vault_response.body)['data'][field.to_s]
                        end
    rescue StandardError
      raise Puppet::Error, 'Error parsing json secret data from vault response'
    end

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(resolved_secret)
  end

  def unwrap(token_path, connection)
    begin
      token_data = File.read(token_path)
      wrapped_token = JSON.parse(token_data)['token']
    rescue StandardError
      raise Puppet::Error, "Unable to parse wrapped token at #{token_path}"
    end

    header = { 'X-Vault-Token' => wrapped_token }
    request_headers = Net::HTTP::Post.new('/v1/sys/wrapping/unwrap', header)
    vault_response = connection.request(request_headers)
    resolved_token = JSON.parse(vault_response.body)['data']['token']

    resolved_token
  end
end
