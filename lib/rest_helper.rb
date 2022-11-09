require_relative 'runner'
require 'net/http'
require 'uri'
require 'json'
require 'pry'

class RestHelper
  
  API_ENDPOINT = 'testops-collector-stag.us-east-1.elasticbeanstalk.com'.freeze
  BUILDS = '/api/v1/builds'.freeze
  EVENT = '/api/v1/event'.freeze
  STOP = '/stop'.freeze

  def launchTestSession(data, user_name, access_key)
    endpoint = "http://#{API_ENDPOINT}#{BUILDS}"
    headers = { 'Content-Type' => 'application/json' }
    uri = URI.parse(endpoint)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(user_name, access_key)
    request.content_type = headers['Content-Type']
    request.body = JSON.dump(data)
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    p "/build success status code - #{response.code} body - #{response.body}" if response.code == '200'
    p "/build api failed with #{response.code}" if response.code != '200'
    JSON.parse(response.body)
  end

  def stopBuildUpstream(data, jwt_token, build_hashed_id)
    data = data.to_s
    endpoint = "http://#{API_ENDPOINT}#{BUILDS}/#{build_hashed_id}#{STOP}"
    headers = {
      'Authorization' => "Bearer #{jwt_token}",
      'Content-Type' => 'application/json',
      'X-BSTACK-TESTOPS': 'true'
    }
    uri = URI(endpoint)
    req = Net::HTTP::Put.new(uri.path, initheader = headers)
    req.body = data
    response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
    puts response.code
    p '/stop success' if response.code == '200'
    p "/stop failed with #{response.code}" if response.code != '200'
  end

  def uploadEventData(data, jwt_token)
    endpoint = "http://#{API_ENDPOINT}#{EVENT}"
    headers = {
      'Authorization' => "Bearer #{jwt_token}",
      'Content-Type' => 'application/json',
      'X-BSTACK-TESTOPS': 'true'
    }
    uri = URI.parse(endpoint)
    request = Net::HTTP::Post.new(uri)
    request.content_type = headers['Content-Type']
    request['X-BSTACK-TESTOPS'] = headers['X-BSTACK-TESTOPS']
    request['Authorization'] = headers['Authorization']
    request.body = JSON.dump(data)
    req_options = {
      use_ssl: uri.scheme == 'https',
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    p "/event success status_code #{response.code}, body #{response.body}" if response.code == '200'
    p "/event failed with #{response.code}" if response.code != '200'
  end  
end
