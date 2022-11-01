require_relative 'runner'
require 'uri'
require 'net/http'

class Mygem
  API_ENDPOINT = 'testops-collector-stag.us-east-1.elasticbeanstalk.com'
  BUILDS = '/api/v1/builds'
  

  def custom_formatter(config, ast)
    @runner = Runner.new
    @ast_lookup = ast
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

  def on_test_run_started(event)
    puts "Mygem - inside on_test_run_started - #{event}"
    request_data = create_build_response(current_time)
    res = launchTestSession(request_data)
    res = JSON.parse(res)
    @build_hashed_id = res['build_hashed_id']
    @jwt_token = res['jwt']
  end

  def on_test_case_started(event)
    puts "Mygem - inside on_test_case_started - #{event}"
  end

  def on_test_case_finished(event)
    puts "Mygem - inside on_test_case_finished - #{event}"
  end

  def on_test_step_started(event)
    puts "Mygem - inside test_step_started  - #{event}"
  end

  def on_test_step_finished(event)
    puts "Mygem - test_step_finished - #{event}"
  end

  def on_test_run_finished(event)
    puts "Mygem - inside test_run_finished - #{event}"
    request_data = create_stop_response(current_time)
    stopBuildUpstream(request_data)
  end

  def get_tags_array(tags)
    tags_array = []
    tags.each { |tag| tags_array << tag.name }
    tags_array
  end

  def get_scenario_name(scenario)
    scenario.scenario.name
  end

  # /builds api
  def create_build_response(time)
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
      'version_control' => @runner.version_control
    }
  end

  def launchTestSession(data)
    data = data.to_json
    endpoint = "http://#{API_ENDPOINT}#{BUILDS}"
    auth = "#{@runner.get_username}:#{@runner.get_access_key}"
    headers = 'Content-Type: application/json'
    res = `curl -X POST '#{endpoint}' -u #{auth} -H '#{headers}' -d '#{data}'`
    res
  end

  # /stop api
  def create_stop_response(time)
    { 'stop_time' => time }
  end

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
    p '/stop build failed' if response.code != '200'
  end

  # /events
  def create_events_response()
  end

  def current_time
    Time.now.to_s
  end
end