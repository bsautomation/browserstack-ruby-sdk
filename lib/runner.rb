require 'yaml'
require 'socket'

class Runner
  REPORTER = '--format pretty -f Formatter -o abc.txt'
  def initialize
    p 'Starting ...'
    @input_params = YAML.load_file('browserstack.yml')
  end

  def get_username
    user_name = @input_params['userName'] unless @input_params['userName'].nil?
    if user_name == 'YOUR_USERNAME' || user_name == 'BORWSERSTACK_USERNAME'
      # get data from env
    end
    return user_name
  end

  def get_access_key
    return @input_params['accessKey'] unless @input_params['accessKey'].nil?
  end

  def get_platform_params
    return @input_params['platforms'][0] unless @input_params['platforms'].nil?

    ''
  end

  def get_build_name
    return @input_params['buildName'] unless @input_params['buildName'].nil?

    ''
  end

  def get_project_name
    return @input_params['projectName'] unless @input_params['projectName'].nil?

    ''
  end

  def get_build_tag
    return @input_params['buildTag'] unless @input_params['buildTag'].nil?

    []
  end

  def get_host_machine_info
    {
      'hostname' => Socket.gethostname,
      'platform' => Gem::Platform.local.os,
      'type' => Gem::Platform.local.cpu,
      'version' => Gem::Platform.local.version,
      'arch' => Gem::Platform.local.cpu
    }
  end

  def get_description
    'Dummy_Description'
  end

  def get_ci_info
    {}
  end

  def get_failed_test_rerun
    false
  end

  def version_control
    {}
  end

  def execute_cmd(args)
    exec("#{args} #{REPORTER}")
  end

  def create_cmd
    "cucumber BS_USERNAME=#{get_username} BS_AUTHKEY=#{get_access_key} BS_AUTOMATE_OS=#{get_platform_params['os']} BS_AUTOMATE_OS_VERSION=#{get_platform_params['osVersion']} SELENIUM_BROWSER=#{get_platform_params['browserName']} #{REPORTER}"
  end
end
