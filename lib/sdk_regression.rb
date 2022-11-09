require_relative 'runner'
require_relative 'rest_helper'
require_relative 'data_helper'
require 'securerandom'

$global_obj = {}

class SDK_Regression

  def custom_formatter(config) #cucumber 3.2
    @runner = Runner.new
    @rest_helper = RestHelper.new
    @data_helper = DataHelper.new

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
    request_data = @data_helper.create_build_request(@runner, @data_helper.current_time)
    response = @rest_helper.launchTestSession(request_data, @runner.get_username, @runner.get_access_key)
    @build_hashed_id = response['build_hashed_id'] rescue nil
    @jwt_token = response['jwt'] rescue nil
  end

  # uploadevent api call
  def on_test_case_started(event)
    event_name = 'TestRunStarted'
    file_name = "#{Dir.pwd}/#{event.test_case.feature.file}"
    uuid = SecureRandom.uuid
    feature_name = event.test_case.feature.name
    scenario_name = event.test_case.name
    started_at = @data_helper.current_time

    test_data = @data_helper.test_data(uuid, scenario_name, feature_name, file_name, started_at)
    meta = @data_helper.meta_data(scenario_name, feature_name, file_name)

    $global_obj[uniq_id_by_test_case(event)] = { 'test_data' => test_data, 'meta' => meta }

    test_case_started_data = {
      'event_type' => event_name,
      'test_run' => test_data
    }
    @rest_helper.uploadEventData(test_case_started_data, @jwt_token)
  end

  def on_test_step_started(event)
    test_step = event.test_step.source.last
    uniq_id = uniq_id_by_test_step(event)

    if test_step.class.to_s.include? 'Step'
      step_hash = @data_helper.step_hash(id: rand(10..99), text: test_step.to_s, keyword: test_step.keyword, started_at: @data_helper.current_time)
      $global_obj[uniq_id]['meta']['steps'] << step_hash
    end
  end

  def on_test_step_finished(event)
    test_step = event.test_step.source.last
    uniq_id = uniq_id_by_test_step(event)

    status = @data_helper.test_result(event.result.to_sym)
    duration = @data_helper.get_duration(event, status)

    if test_step.class.to_s.include? 'Step'
      steps_list = $global_obj[uniq_id]['meta']['steps']

      steps_list.each_with_index do |step, index|
        if step['text'].include? event.test_step.source.last.to_s
          steps_list[index]['finished_at'] = @data_helper.current_time
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
    uniq_id = uniq_id_by_test_case(event)
    event_type = 'TestRunFinished'
    test_data = $global_obj[uniq_id]['test_data']
    status = @data_helper.test_result(event.result.to_sym)
    duration = @data_helper.get_duration(event, status)

    test_result_data = @data_helper.test_result_data(event, status, duration, @data_helper.current_time)    
    test_data = test_data.merge(test_result_data)

    test_case_finished_data = {
      'event_type' => event_type,
      'test_run' => test_data
    }
    test_case_finished_data['test_run']['meta'] = $global_obj[uniq_id]['meta']
    @rest_helper.uploadEventData(test_case_finished_data, @jwt_token)
  end

  # stop api call
  def on_test_run_finished(event)
    request_data = @data_helper.create_stop_request(@data_helper.current_time)
    @rest_helper.stopBuildUpstream(request_data, @jwt_token, @build_hashed_id)
  end

  def uniq_id_by_test_case(event)
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
