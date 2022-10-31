require_relative 'runner'
require 'pry'

class Mygem
  def custom_formatter(config, ast)
    @runner = Runner.new
    @ast_lookup = ast
    %i[test_case_started test_case_finished test_step_started test_step_finished test_run_finished].each do |event_name|
      config.on_event event_name do |event|
        case event_name
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

  def on_test_case_started(event)
    puts "LOCAL GEM - inside on_test_case_started - #{event}"
    start_time = current_time
    test_case = event.test_case
    scenario = @ast_lookup.scenario_source(test_case)
    @scenario_name = get_scenario_name(scenario)
    @tags_array = get_tags_array(test_case.tags)
    response_data = create_build_response(start_time)
    make_request(response_data)
  end

  def on_test_case_finished(event)
    puts "LOCAL GEM - inside on_test_case_finished - #{event}"
  end

  def on_test_step_started(event)
    puts "LOCAL GEM - inside test_step_started  - #{event}"
  end

  def on_test_step_finished(event)
    puts "LOCAL GEM - test_step_finished - #{event}"
  end

  def on_test_run_finished(event)
    puts "LOCAL GEM - inside test_run_finished - #{event}"
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
      'tags' => @tags_array,
      'host_info' => @runner.get_host_machine_info,
      'ci_info' => @runner.get_ci_info,
      'failed_tests_rerun' => @runner.get_failed_test_rerun,
      'version_control' => @runner.version_control
    }
  end

  # /stop api
  def create_stop_response()
  end

  # /events
  def create_events_response()
  end

  def make_request(data)
    data = data.to_json
    request = "curl -d '#{data}' -H 'Content-Type: application/json' -X POST http://localhost:4000/time --silent"
    `#{request}`
  end

  def current_time
    Time.now
  end
end