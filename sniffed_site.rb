class SniffedSite
  attr_accessor :driver, :data

  TOOLS = ['sentry','rollbar','logrocket','datadog','bugsnag','newrelic']

  def initialize(driver)
    @driver   = driver
    @data = {}
    detect_presence!
  end

  def detect_presence!
    TOOLS.each do |tool_name|
      data[tool_name] = {}

      # check whether tool exists
      data[tool_name][:detected] = send("has_#{tool_name}")

      # if tool exists, note the location (url) it was detected at
      # plus any additional metadata
      if data[tool_name][:detected]
        data[tool_name][:location] = location

        ### TODO: figure out how to get 'n/a' in the end csv
        # in the event that sentry is not sniffed at all on any page.
        # since, we can't just ignore these columns (right?)
        if tool_name == 'sentry'
          detect_additional_metadata!(tool_name)
        end
      end

      @data = data
    end
  end

  def location
    driver.execute_script("return window.location.href")
  end

  def detect_additional_metadata!(tool_name)
    puts("-----------------")
    puts("TODO: detecting add'l sentry context...")
    puts("-----------------")
    sentry = @data["sentry"]
    sentry[:sdk_version] = determine_sdk || 'n/a'
    sentry[:dsn_host] = dsn_host || 'n/a'
    sentry[:project_id] = project_id || 'n/a'
    # sentry[:uses_sentry_performance] = uses_sentry_performance?
    # sentry[:performance_sample_rate] = sentry_performance_sample_rate
    # sentry[:error_sample_rate] = sentry_error_sample_rate
    # sentry[:dsn_host] = dsn_host
    # sentry[:project_id] = sentry_project_id
    # detect various metadata and put it under
    # data[:sentry]. For example:
    #   data[:sentry][:sampleRatePerformance] = ...
    #   data[:sentry][:sampleRateErrors] = ...
    #   data[:sentry][:sdkVersion] = ...
  end

  def detected_any_sdks?
    @data.each do |tool_name,details|
      return true if details[:detected]
    end
    false
  end

  private

  def has_sentry
    driver.execute_script("return !!window.Sentry || !!window.__SENTRY__ || !!window.Raven;")
  end

  def has_newrelic
    driver.execute_script("return !!window.newrelic;")
  end

  def has_bugsnag
    driver.execute_script("return !!window.Bugsnag || !!window.bugsnag || !!window.bugsnagClient;")
  end

  def has_rollbar
    driver.execute_script("return !!window._rollbarDidLoad;")
  end

  def has_datadog
    driver.execute_script("return !!window.DD_RUM;")
  end

  def has_logrocket
    driver.execute_script("return !!window._lr_loaded;")
  end

  def dsn_host
    if sentry_global_var_exists?
      driver.execute_script("return __SENTRY__.hub.getClient().getDsn().host")
    end
  end

  def project_id
    if sentry_global_var_exists?
      driver.execute_script("return __SENTRY__.hub.getClient().getDsn().projectId")
    end
  end

  def determine_sdk
    if sentry_global_var_exists?
      options = sentry_options
      options['_metadata'] ? options['_metadata'] : '<unable to determine>'
    end
  end

  def sentry_global_var_exists?
    driver.execute_script("return typeof __SENTRY__ != 'undefined'")
  end

  def sentry_options
    driver.execute_script("return __SENTRY__.hub.getClient().getOptions()")
  end

end