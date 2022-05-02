class ObservabilityProductSniffer
  attr_reader :site, :driver

  def initialize(site)
    @site = site
  end

  def sniff
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    @driver = Selenium::WebDriver.for :chrome, capabilities: options
    @driver.manage.timeouts.page_load = 10 # seconds
    
    begin
      puts "Scraping #{site}"
      driver.get(site)
      #############
      # here, we need to try to find instances of hyperlinks with the text
      # login, signin, log in, sign in.
      # If we find any links matching any of these, we should then navigate
      # to the found page.
      #############
      return {
        tools_used: tools_used,
        error: nil
      }
    rescue StandardError => e
      # could capture the exception and do something with it. shrug
      return {
        tools_used: nil,
        error: e
      }
    ensure
      begin
        driver.quit
      rescue StandardError => e
        # could capture the exception and do something with it. shrug
        return {
          tools_used: nil,
          error: e
        }
      end
    end
  end

  def tools_used
    tools = []
    tools << 'sentry' if sentry?
    tools << 'newrelic' if newrelic?
    tools << 'bugsnag' if bugsnag?
    tools << 'rollbar' if rollbar?
    tools << 'datadog' if datadog?
    tools << 'logrocket' if logrocket?
    tools
  end

  private

  def sentry?
    driver.execute_script("return !!window.Sentry || !!window.__SENTRY__ || !!window.Raven;")
  end

  def newrelic?
    driver.execute_script("return !!window.newrelic;")
  end

  def bugsnag?
    driver.execute_script("return !!window.Bugsnag || !!window.bugsnag || !!window.bugsnagClient;")
  end

  def rollbar?
    driver.execute_script("return !!window._rollbarDidLoad;")
  end

  def datadog?
    driver.execute_script("return !!window.DD_RUM;")
  end

  def logrocket?
    driver.execute_script("return !!window._lr_loaded;")
  end
end
