require_relative 'runner'
require 'uri'
require 'json'
require 'net/http'

class Mygem
  API_ENDPOINT = 'testops-collector-stag.us-east-1.elasticbeanstalk.com'.freeze
  BUILDS = '/api/v1/builds'.freeze

  def custom_formatter(config, ast)
    @runner = Runner.new
    @ast_lookup = ast
    %i[gherkin_source_read gherkin_source_parsed test_run_started test_case_started test_case_finished test_step_started test_step_finished test_run_finished].each do |event_name|
      config.on_event event_name do |event|
        case event_name
        when :gherkin_source_read
          on_gherkin_source_read(event)
        when :gherkin_source_parsed
          on_gherkin_source_parsed(event)
        when :test_run_started
          on_test_run_started(event)
        when :test_case_started
          on_test_case_started(event)
        when :test_case_finished
          on_test_case_finished(event)
        when :test_step_started
          on_test_step_started(event)
        when :test_step_finished
          on_test_step_finished(event)
        when :test_run_finished
          on_test_run_finished(event)
        else
          p "UNKNOWN#{event_name}"
        end
      end
    end
  end

  def on_gherkin_source_read(event)
    # binding.pry
  end

  def on_gherkin_source_parsed(event)
    @feature_name = event.gherkin_document.feature.name
    # binding.pry
  end

  def on_test_run_started(event)
    puts "Mygem - inside on_test_run_started - #{event}"
    request_data = create_build_request(current_time)
    launchTestSession(request_data)
  end

  def on_test_case_started(event)
    # puts "Mygem - inside on_test_case_started - #{event}"
    event_name = 'TestRunStarted'
    relative_location = event.test_case.location.file
    @file_name = "#{Dir.pwd}/#{relative_location}"
    @uuid = event.test_case.id
    @scenario_name = event.test_case.name
    @started_at = current_time
    test_data = test_data(event_name)
    data = {
      'event_type' => event_name,
      'test_run' => test_data
    }
    uploadEventData(data)
  end

  def on_test_case_finished(event)
    # puts "Mygem - inside on_test_case_finished - #{event}"
    finished_at = current_time
    event_type = 'TestRunFinished'
    test_data = test_data(event_type)

    status = test_result(event.result.to_sym)
    duration = event.result.duration.nanoseconds.to_i/1000000.to_f
    test_result_data = {
      'result' => status,
      'finished_at' => finished_at,
      'duration_in_ms' => duration
    }
    test_data = test_data.merge(test_result_data)
    if status == 'failed'
      failure_data = {
        'failure_reason' => event.result.exception.message,
        'failure' => [{ 'backtrace' => event.result.exception.backtrace }],
        'failure_type' => event.result.exception.class.to_s.include?('AssertionError') ? 'AssertionError' : 'UnhandledError'
      }
      test_data = test_data.merge(failure_data)
    end
    data = {
      'event_type' => event_type,
      'test_run' => test_data
    }
    uploadEventData(data)
  end

  def on_test_step_started(event)
    # binding.pry
    # puts "Mygem - inside test_step_started  - #{event}"
  end

  def on_test_step_finished(event)
    # puts "Mygem - test_step_finished - #{event}"
  end

  def on_test_run_finished(event)
    # puts "Mygem - inside test_run_finished - #{event}"
    request_data = create_stop_request(current_time)
    stopBuildUpstream(request_data)
  end

  # /event api data
  def test_data(event_name)
    {
      'framework' => 'cucumber',
      'uuid' => @uuid,
      'name' => @scenario_name,
      'type' => 'test',
      'body' => {
        'lang' => 'Ruby',
        'code' => ''
      },
      'scope' => "#{@feature_name} - #{@scenario_name}",
      'scopes' => [@scenario_name, @feature_name],
      'identifier' => "#{@feature_name} - #{@scenario_name}",
      'file_name' => @file_name,
      'location' => @file_name,
      'started_at' => @started_at
      # meta 
    }
  end

  # /builds api data
  def create_build_request(time)
    {
      'format' => 'json',
      'project_name' => @runner.get_project_name,
      'name' => @runner.get_build_name,
      'description' => @runner.get_description,
      'start_time' => time,
      'tags' => @runner.get_build_tag,
      'host_info' => @runner.get_host_machine_info,
      # 'ci_info' => @runner.get_ci_info,
      'failed_tests_rerun' => @runner.get_failed_test_rerun,
      # 'version_control' => @runner.version_control
    }
  end

  # /stop api data
  def create_stop_request(time)
    { 'stop_time' => time }
  end

  # /build api
  def launchTestSession(data)
    endpoint = "http://#{API_ENDPOINT}#{BUILDS}"
    headers = { 'Content-Type' => 'application/json' }
    uri = URI.parse(endpoint)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@runner.get_username, @runner.get_access_key)
    request.content_type = headers['Content-Type']
    request.body = JSON.dump(data)
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    p "/build api failed with #{response.code}" unless response.code == '200'
    response = JSON.parse(response.body)
    @build_hashed_id = response['build_hashed_id']
    @jwt_token = response['jwt']
    require 'pry'
    
    # binding.pry
  end

  # /stop api
  def stopBuildUpstream(data)
    data = data.to_s
    endpoint = "http://#{API_ENDPOINT}#{BUILDS}/#{@build_hashed_id}/stop"
    headers = {
      'Authorization' => "Bearer #{@jwt_token}",
      'Content-Type' => 'application/json',
      'X-BSTACK-TESTOPS': 'true'
    }
    uri = URI(endpoint)
    req = Net::HTTP::Put.new(uri.path, initheader = headers)
    req.body = data
    response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
    puts response.code
    p "/stop failed with #{response.code}" if response.code != '200'
  end

  # /event api
  def uploadEventData(data)
    endpoint = "http://#{API_ENDPOINT}/api/v1/event"
    headers = {
      'Authorization' => "Bearer #{@jwt_token}",
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
    p "/event failed with #{response.code}" if response.code != '200'
  end

  def current_time
    Time.now.iso8601
  end

  def test_result(status)
    case status
    when :passed
      'passed'
    when :failed
      'failed'
    else
      'skipped'
    end
  end

  def finished?(event_name)
    event_name.include?('Finished')
  end
end
