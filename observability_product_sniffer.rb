class ObservabilityProductSniffer
  attr_reader :site, :driver

  def initialize(site)
    @site = site
  end

  def sniff
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument("--disable-notifications")
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

        # using elements plural here to avoid error-throwing, and then jsut selecting first result
        sign_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'sign in')]").map{|el| el.attribute('href')}
        log_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'log in')]").map{|el| el.attribute('href')}
        login = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'login')]").map{|el| el.attribute('href')}
        account = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'account')]").map{|el| el.attribute('href')}

        url = nil
        if !sign_in.empty?
          detected_on = 'sign in'
          url = sign_in.first
        elsif !log_in.empty?
          detected_on = 'log in'
          url = log_in.first
        elsif !login.empty?
          detected_on = 'login (no space)'
          url = login.first
        elsif !account.empty?
          detected_on = 'account'
          url = account.first
        else
          detected_on = 'n/a'
        end

        if url
          puts "    -> " + url
          driver.navigate.to url
        end
      end

      return {
        tools_used: tools_used,
        detected_on: tools_used.empty? ? "n/a" : detected_on,
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
