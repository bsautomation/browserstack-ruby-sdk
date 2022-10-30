
class Mygem
  def build_abc(config, ast)
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
    puts "inside on_test_case_started - #{event}"
    test_case = event.test_case
    scenario = @ast_lookup.scenario_source(test_case)
    scenario_name = get_scenario_name(scenario)
    tags_array = get_tags_array(test_case.tags)
    puts "tags_array - #{tags_array}, scenario_name - ##{scenario_name}"
  end

  def on_test_case_finished(event)
    puts "inside on_test_case_finished - #{event}"
  end

  def on_test_step_started(event)
    puts "inside test_step_started  - #{event}"
  end

  def on_test_step_finished(event)
    puts "inside test_step_finished - #{event}"
  end

  def on_test_run_finished(event)
    puts "inside test_run_finished - #{event}"
  end

  def get_tags_array(tags)
    tags_array = []
    tags.each { |tag| tags_array << tag.name }
    tags_array
  end

  def get_scenario_name(scenario)
    scenario.scenario.name
  end
end
