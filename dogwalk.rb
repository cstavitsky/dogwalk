require 'selenium-webdriver'
require 'pry'
require './observability_product_sniffer.rb'
require './salesforce_csv_parser.rb'
require './yc_client.rb'
require './csv_parser.rb'

puts "Starting scraping."
# companies = YCClient.company_data #leaving as example
companies = SalesforceCSVParser.new.company_data
# companies = companies[10...30] #truncate while i test if this works. remove line when running for real
problems_scraping = nil
formatted_list = []
companies.each do |company|
  observability_products_detected = ObservabilityProductSniffer.new(company.website).sniff
  captured_error = observability_products_detected[:error]
  # binding.pry
  if captured_error
    puts "Could not detect observability for #{company.name} -- #{captured_error.message}"
    problems_scraping = captured_error.message
    observability_products_detected = ''
  else
    problems_scraping = nil
    observability_products_detected = observability_products_detected.empty? ? '' : observability_products_detected[:tools_used]
  end
  
  org_details = {
    company: company.name,
    website: company.website,
    uses_sentry: observability_products_detected.include?('sentry'),
    uses_rollbar: observability_products_detected.include?('rollbar'),
    uses_logrocket: observability_products_detected.include?('logrocket'),
    uses_newrelic: observability_products_detected.include?('newrelic'),
    uses_datadog: observability_products_detected.include?('datadog'),
    uses_bugsnag: observability_products_detected.include?('bugsnag'),
    segment: company.segment,
    total_touch_arr: company.total_touch_arr,
    id: company.id,
    owner: company.owner,
    problems_scraping: problems_scraping
  }
  formatted_list << org_details
end

formatted_list.to_csv
puts "Finished scraping. #{companies.length} companies scraped."



