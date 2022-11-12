class ObservabilityProductSniffer
  attr_reader :site, :driver
  require('./sniffed_site.rb')

  def initialize(site)
    @site = site
  end

  def sniff
    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_argument('--headless')
    options.add_argument("--disable-notifications")
    @driver = Selenium::WebDriver.for :chrome, capabilities: options
    @driver.manage.timeouts.page_load = 10 # seconds
    
    begin
      puts "Scraping #{site}"
      detected_on = nil

      #navigate to homepage
      driver.get(site)

      ###################################################
      ###################################################
      ####### CHECK MAIN HOMEPAGE #######################
      #####  FOR OBSERVABILITY TOOLS ####################
      ###################################################
      ###################################################
      current_tools = tools_used
      if detected_any_sdks?(current_tools)
        return {
          tools_used: current_tools,
          detected_on: 'homepage',
          error: nil
        }
      end

      ###################################################
      ###################################################
      ###### CHECK ALL HOMEPAGE FRAMES ##################
      ######  FOR OBSERVABILITY TOOLS ###################
      ###################################################
      ###################################################

      all_frames = driver.find_elements(:css,'iframe')
      all_frames.each do |frame|
        # Switch to the frame
        # check_frame_for_sentry(driver, frame)
        driver.switch_to.frame frame

        current_tools = tools_used
        if detected_any_sdks?(current_tools)
          return {
            tools_used: current_tools,
            detected_on: 'homepage (iframe)',
            error: nil
          }
        end
        
        driver.switch_to.default_content
      end

      # if no observability tool was detected on the homepage,
      # navigate to login/account/sign in page, because these are more
      # likely to contain app code and therefore observability monitoring.

      # using elements plural here to avoid error-throwing, and then jsut selecting first result
      sign_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'sign in')]").map{|el| el.attribute('href')}
      signin = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'signin')]").map{|el| el.attribute('href')}
      log_in = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'log in')]").map{|el| el.attribute('href')}
      login = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'login')]").map{|el| el.attribute('href')}
      account = driver.find_elements(:xpath, "//a[contains(translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'account')]").map{|el| el.attribute('href')}

      url = nil
      if !sign_in.empty?
        detected_on = sign_in.first
        url = sign_in.first
      elsif !signin.empty?
        detected_on = signin.first
        url = signin.first
      elsif !log_in.empty?
        detected_on = log_in.first
        url = log_in.first
      elsif !login.empty?
        detected_on = login.first
        url = login.first
      elsif !account.empty?
        detected_on = account.first
        url = account.first
      else
        detected_on = 'n/a'
      end

      if url
        puts "    -> " + url
        driver.navigate.to url
        
        ###################################################
        ###################################################
        ######## CHECK ALL LOGIN PAGE FRAMES ##############
        ########  FOR OBSERVABILITY TOOLS #################
        ###################################################
        ###################################################
        all_frames = driver.find_elements(:css,'iframe')
        all_frames.each do |frame|
          # Switch to the frame
          # check_frame_for_sentry(driver, frame)
          driver.switch_to.frame frame
          
          current_tools = tools_used
          if detected_any_sdks?(current_tools)
            return {
              tools_used: current_tools,
              detected_on: detected_on,
              error: nil
            }
          end
          
          driver.switch_to.default_content
        end
      end


      return {
        tools_used: current_tools,
        detected_on: 'n/a',
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
    SniffedSite.new(driver)
  end

  def detected_any_sdks?(sniffed_site)
    sniffed_site.detected_any_sdks?
  end

  def detected_one_or_more_observability_tools?
    tools_used.each do |tool|
      return true if tool[:detected]
    end
  end
end
