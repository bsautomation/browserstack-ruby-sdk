require_relative 'runner'
require 'uri'
require 'json'
require 'net/http'
require 'securerandom'

$global_obj = {}

class MygemB
  API_ENDPOINT = 'testops-collector-stag.us-east-1.elasticbeanstalk.com'.freeze
  BUILDS = '/api/v1/builds'.freeze

  def custom_formatter(config) #cucumber 3.2
    @runner = Runner.new
    %i[test_run_started test_case_started test_case_finished test_step_started test_step_finished test_run_finished].each do |event_name|
      config.on_event event_name do |event|
        case event_name
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

  # launch api call
  def on_test_run_started(event)
    request_data = create_build_request(current_time)
    launchTestSession(request_data)
  end

  # uploadevent api call
  def on_test_case_started(event)
    event_name = 'TestRunStarted'
    @file_name = "#{Dir.pwd}/#{event.test_case.feature.file}"
    @uuid = SecureRandom.uuid
    @feature_name = event.test_case.feature.name
    @scenario_name = event.test_case.name
    @started_at = current_time
    @step_list = []
    test_data = test_data(event_name)
    meta = {
      'feature' => {
        'path' => @file_name,
        'name' => @feature_name,
        'description' => ''
      },
      'scenario' => {
        'name' => @scenario_name
      },
      'steps' => []
    }
    $global_obj[uniq_id_by_test_case(event)] = { 'test_data' => test_data, 'meta' => meta }
    @test_case_started_data = {
      'event_type' => event_name,
      'test_run' => test_data
    }
    uploadEventData(@test_case_started_data)
  end

  def on_test_step_started(event)
    test_step = event.test_step.source.last
    uniq_id = uniq_id_by_test_step(event)

    if test_step.class.to_s.include? 'Step'
      step_hash = {
        'id' => rand(10..99),
        'text' => test_step.to_s,
        'keyword' => test_step.keyword,
        'started_at' => current_time
      }
      $global_obj[uniq_id]['meta']['steps'] << step_hash
      @step_list << step_hash
    end
  end

  def on_test_step_finished(event)

    test_step = event.test_step.source.last
    uniq_id = uniq_id_by_test_step(event)

    status = test_result(event.result.to_sym)
    duration = get_duration(event, status)

    if test_step.class.to_s.include? 'Step'
      steps_list = $global_obj[uniq_id]['meta']['steps']

      steps_list.each_with_index do |step, index|
        if step['text'].include? event.test_step.source.last.to_s
          steps_list[index]['finished_at'] = current_time
          steps_list[index]['result'] = status
          steps_list[index]['duration'] = duration
          steps_list[index]['failure'] = event.result.exception.message if status == 'failed'
        end
      end
      $global_obj[uniq_id]['meta']['steps'] = steps_list
    end
  end

  # upload event api call
  def on_test_case_finished(event)
    finished_at = current_time
    event_type = 'TestRunFinished'
    uniq_id = uniq_id_by_test_case(event)
    test_data = $global_obj[uniq_id]['test_data']
    status = test_result(event.result.to_sym)
    duration = get_duration(event, status)
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
    @test_case_finished_data = {
      'event_type' => event_type,
      'test_run' => test_data
    }
    @test_case_finished_data['test_run']['meta'] = $global_obj[uniq_id]['meta']
    binding.pry
    uploadEventData(@test_case_finished_data)
    
  end

  # stop api call
  def on_test_run_finished(event)
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
      'ci_info' => @runner.get_ci_info,
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
    p "/build success status code - #{response.code} body - #{response.body}" if response.code == '200'
    p "/build api failed with #{response.code}" if response.code != '200'
    response = JSON.parse(response.body)
    @build_hashed_id = response['build_hashed_id']
    @jwt_token = response['jwt']
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
    p '/stop success' if response.code == '200'
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
    p "/event success status_code #{response.code}, body #{response.body}" if response.code == '200'
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

  def get_duration(event, status)
    if status.include?('skipped') || event.result.duration.instance_of?(Cucumber::Core::Test::Result::UnknownDuration)
      0
    else
      event.result.duration.nanoseconds.to_f/1000000 rescue 0
    end
  end

  def finished?(event_name)
    event_name.include?('Finished')
  end

  def uniq_id_by_test_case (event)
    scenario_object = ''
    event.test_case.source.each { |element|
      keyword = element.keyword rescue nil
      scenario_object = element if !keyword.nil? && keyword.include?('Scenario')
    }
    "#{scenario_object.to_s}_#{scenario_object.location.file}_#{scenario_object.location.lines.to_s}"
  end

  def uniq_id_by_test_step(event)
    scenario_object = ''
    event.test_step.source.each { |element|
      keyword = element.keyword rescue nil
      scenario_object = element if !keyword.nil? && keyword.include?('Scenario')
    }
    "#{scenario_object.to_s}_#{scenario_object.location.file}_#{scenario_object.location.lines.to_s}"
  end
end
