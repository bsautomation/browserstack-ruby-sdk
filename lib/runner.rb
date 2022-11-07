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
    if user_name == 'YOUR_USERNAME' || user_name == 'BROWSERSTACK_USERNAME'
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
    # Jenkins
    if (!ENV['JENKINS_URL'].nil? && ENV['JENKINS_URL'].instance_of?(String) && ENV['JENKINS_URL'].size > 0) || (!ENV['JENKINS_HOME'].nil? && ENV['JENKINS_HOME'].instance_of?(String) && ENV['JENKINS_HOME'].size > 0)
      return {
          'name' => 'Jenkins',
          'build_url' => ENV['BUILD_URL'],
          'job_name' => ENV['JOB_NAME'],
          'build_number' => ENV['BUILD_NUMBER']
      }
    end

    # CircleCI
    if !ENV['CI'].nil? && !ENV['CIRCLECI'].nil?
      return {
        'name' => 'CircleCI',
        'build_url' => ENV['CIRCLE_BUILD_URL'],
        'job_name' => ENV['CIRCLE_JOB'],
        'build_number' => ENV['CIRCLE_BUILD_NUM']
      }
    end

    # Travis CI
    if !ENV['CI'].nil? && !ENV['TRAVIS'].nil?
      return {
        'name' => 'Travis CI',
        'build_url' => ENV['TRAVIS_BUILD_WEB_URL'],
        'job_name' => ENV['TRAVIS_JOB_NAME'],
        'build_number' => ENV['TRAVIS_BUILD_NUMBER']
      }
    end

    # Codeship
    if !ENV['CI'].nil? && !ENV['CI_NAME'].nil? && ENV['CI_NAME'] == 'codeship'
      return {
        'name' => 'Codeship',
        'build_url' => nil,
        'job_name' => nil,
        'build_number' => nil
      }
    end

    if !ENV['BITBUCKET_BRANCH'].nil? && !ENV['BITBUCKET_COMMIT'].nil?
      return {
        'name' => 'Bitbucket',
        'build_url' => ENV['BITBUCKET_GIT_HTTP_ORIGIN'],
        'job_name' => null,
        'build_number' => ENV['BITBUCKET_BUILD_NUMBER']
      }
    end

    if !ENV['CI'].nil? && !ENV['DRONE']
      return {
        'name' => 'Drone',
        'build_url' => ENV['DRONE_BUILD_LINK'],
        'job_name' => null,
        'build_number' => ENV['DRONE_BUILD_NUMBER']
      }
    end

    if !ENV['CI'].nil? && !ENV['SEMAPHORE'].nil?
      return {
        'name' => 'Semaphore',
        'build_url' => ENV['SEMAPHORE_ORGANIZATION_URL'],
        'job_name' => ENV['SEMAPHORE_JOB_NAME'],
        'build_number' => ENV['SEMAPHORE_JOB_ID']
      }
    end

    if !ENV['CI'].nil? && !ENV['GITLAB_CI'].nil?
      return {
        'name' => 'GitLab',
        'build_url' => ENV['CI_JOB_URL'],
        'job_name' => ENV['CI_JOB_NAME'],
        'build_number' => ENV['CI_JOB_ID']
      }
    end

    if !ENV['CI'].nil? && !ENV['BUILDKITE'].nil?
      return {
        'name' => 'Buildkite',
        'build_url' => ENV['BUILDKITE_BUILD_URL'],
        'job_name' => ENV['BUILDKITE_LABEL'] || ENV['BUILDKITE_PIPELINE_NAME'],
        'build_number' => ENV['BUILDKITE_BUILD_NUMBER']
      }
    end

    if !ENV['TF_BUILD'].nil?
      return {
        'name' => 'Visual Studio Team Services',
        'build_url' => "#{ENV['SYSTEM_TEAMFOUNDATIONSERVERURI']}#{ENV['SYSTEM_TEAMPROJECTID']}",
        'job_name' => ENV['SYSTEM_DEFINITIONID'],
        'build_number' => ENV['BUILD_BUILDID']
      }
    end

    nil
  end

  def get_failed_test_rerun
    false
  end

  def version_control
    {}
  end

  def execute_cmd(args)
    if args.include? 'cucumber'
      exec("#{args} #{REPORTER}")
    else
      # regression
      exec(args)
    end
  end

  # def create_cmd
  #   "cucumber BS_USERNAME=#{get_username} BS_AUTHKEY=#{get_access_key} BS_AUTOMATE_OS=#{get_platform_params['os']} BS_AUTOMATE_OS_VERSION=#{get_platform_params['osVersion']} SELENIUM_BROWSER=#{get_platform_params['browserName']} #{REPORTER}"
  # end
end
