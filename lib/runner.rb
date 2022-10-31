require 'yaml'

class Runner
  REPORTER = '--format pretty -f Formatter -o abc.txt'
  def initialize
    @input_params = YAML.load_file('browserstack.yml')
  end

  def get_username
    return @input_params['userName'] unless @input_params['userName'].nil?
  end

  def get_access_key
    return @input_params['accessKey'] unless @input_params['accessKey'].nil?
  end

  def get_platform_params
    return @input_params['platforms'][0] unless @input_params['platforms'].nil?
  end

  def get_build_name
    return @input_params['buildName'] unless @input_params['buildName'].nil?
  end

  def get_project_name
    return @input_params['projectName'] unless @input_params['projectName'].nil?
  end

  def create_cmd
    "cucumber BS_USERNAME=#{get_username} BS_AUTHKEY=#{get_access_key} BS_AUTOMATE_OS=#{get_platform_params['os']} BS_AUTOMATE_OS_VERSION=#{get_platform_params['osVersion']} SELENIUM_BROWSER=#{get_platform_params['browserName']} #{REPORTER}"
  end

  def execute_cmd
    exec(create_cmd)
  end
end