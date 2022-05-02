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
      detected_on = nil

      #navigate to homepage
      driver.get(site)

      if !tools_used.empty?
        detected_on = 'homepage'
      else
        # if no observability tool was detected on the homepage,
        # navigate to login/account/sign in page, because these are more
        # likely to contain app code and therefore observability monitoring.
        sign_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'sign in')]")
        log_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'log in')]")
        login = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'login')]")
        account = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'account')]")

        if !sign_in.empty?
          detected_on = 'sign in'
          sign_in.first.click
        elsif !log_in.empty?
          detected_on = 'log in'
          log_in.first.click
        elsif !login.empty?
          detected_on = 'login (no space)'
          login.first.click
        elsif !account.empty?
          detected_on = 'account'
          account.first.click
        else
          detected_on = 'n/a'
        end
      end

      return {
        tools_used: tools_used,
        detected_on: detected_on,
        error: nil
      }
    rescue StandardError => e
      # could capture the exception and do something with it. shrug
      return {
        tools_used: nil,
        detected_on: nil,
        error: e
      }
    ensure
      begin
        driver.quit
      rescue StandardError => e
        # could capture the exception and do something with it. shrug
        return {
          tools_used: nil,
          detected_on: nil,
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
