class DataHelper
  
  # /builds api data
  def create_build_request(runner, time)
    {
      'format' => 'json',
      'project_name' => runner.get_project_name,
      'name' => runner.get_build_name,
      'description' => runner.get_description,
      'start_time' => time,
      'tags' => runner.get_build_tag,
      'host_info' => runner.get_host_machine_info,
      'ci_info' => runner.get_ci_info,
      'failed_tests_rerun' => runner.get_failed_test_rerun
      # 'version_control' => @runner.version_control
    }
  end

  # /stop api data
  def create_stop_request(time)
    { 'stop_time' => time }
  end

  # /event api data
  def test_data(uuid, scenario_name, feature_name, file_name, started_at)
    {
      'framework' => 'cucumber',
      'uuid' => uuid,
      'name' => scenario_name,
      'type' => 'test',
      'body' => {
        'lang' => 'Ruby',
        'code' => ''
      },
      'scope' => "#{feature_name} - #{scenario_name}",
      'scopes' => [scenario_name, feature_name],
      'identifier' => "#{feature_name} - #{scenario_name}",
      'file_name' => file_name,
      'location' => file_name,
      'started_at' => started_at
    }
  end

  def meta_data(scenario_name, feature_name, file_name)
    {
      'feature' => {
        'path' => file_name,
        'name' => feature_name,
        'description' => ''
      },
      'scenario' => {
        'name' => scenario_name
      },
      'steps' => []
    }
  end

  def test_result_data(event, status, duration, time)
    test_result_data = {
      'result' => status,
      'finished_at' => time,
      'duration_in_ms' => duration
    }
    if status == 'failed'
      failure_data = {
        'failure_reason' => event.result.exception.message,
        'failure' => [{ 'backtrace' => event.result.exception.backtrace }],
        'failure_type' => event.result.exception.class.to_s.include?('AssertionError') ? 'AssertionError' : 'UnhandledError'
      }
      test_result_data = test_result_data.merge(failure_data)
    end
    test_result_data
  end

  def step_hash(**args)
    step_hash = {
      'id' => args[:id],
      'text' => args[:text],
      'keyword' => args[:keyword]
    }
    step_hash['started_at'] = args[:started_at] unless args[:started_at].nil?
    step_hash
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

  def current_time
    Time.now.iso8601
  end
end