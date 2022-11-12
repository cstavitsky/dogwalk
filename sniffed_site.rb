class SniffedSite
  attr_accessor :driver, :data

  TOOLS = ['sentry','rollbar','logrocket','datadog','bugsnag','newrelic']

  def initialize(driver)
    @driver   = driver
    @data = {}
    # @data = {
    #   sentry: {
    #     detected: true,
    #     location: ...,
    #     sampleRatePerformance: ...,
    #     sampleRateErrors: ...,
    #   },
    #   datadog: {
    #     detected: false,
    #     location: ...
    #   }
    # }
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
        detect_additional_metadata!(tool_name)
      end

      @data = data
    end
  end

  def location
    driver.execute_script("return window.location.href")
  end

  def detect_additional_metadata!(tool_name)
    if tool_name == 'sentry'
      puts("-----------------")
      puts("TODO: detecting add'l sentry context...")
      puts("-----------------")
      # detect various metadata and put it under
      # data[:sentry]. For example:
      #   data[:sentry][:sampleRatePerformance] = ...
      #   data[:sentry][:sampleRateErrors] = ...
      #   data[:sentry][:sdkVersion] = ...
    end
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

end