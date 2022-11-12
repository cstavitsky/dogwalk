require 'selenium-webdriver'
require 'pry'
require './observability_product_sniffer.rb'
require './salesforce_csv_parser.rb'
require './yc_client.rb'
require './csv_parser.rb'

puts "Starting scraping."
# companies = YCClient.company_data #leaving as example
companies = SalesforceCSVParser.new("./dog_walker_v2_11_9_22.csv").company_data
companies = companies[0...2] #truncate while i test if this works. remove line when running for real
problems_scraping = nil
formatted_list = []
companies.each do |company|
  observability_products_detected = ObservabilityProductSniffer.new(company.website).sniff
  detected_on = observability_products_detected[:detected_on]
  captured_error = observability_products_detected[:error]
  if captured_error
    puts "Could not detect observability for #{company.name} -- #{captured_error.message}"
    problems_scraping = captured_error.message
    detected_on = "errored out - please examine this site manually"
    observability_products_detected = ''
  else
    problems_scraping = nil
    observability_products_detected = observability_products_detected.empty? ? '' : observability_products_detected[:tools_used]
  end
  
  sniffed_data = observability_products_detected.data
  org_details = {
    # segment: company.segment,
    # total_touch_arr: company.total_touch_arr,
    id: company.id,
    owner: company.owner,
    detected_on: detected_on,
    problems_scraping: problems_scraping,
    company: company.name,
    website: company.website,
    uses_rollbar: sniffed_data['rollbar'][:detected],
    uses_logrocket: sniffed_data['logrocket'][:detected],
    uses_newrelic: sniffed_data['newrelic'][:detected],
    uses_datadog: sniffed_data['datadog'][:detected],
    uses_bugsnag: sniffed_data['bugsnag'][:detected],
    uses_sentry: sniffed_data["sentry"][:detected],
    sentry_sdk_version: sniffed_data['sentry'][:sdk_version],
    sentry_dsn_host: sniffed_data['sentry'][:dsn_host],
    sentry_project_id: sniffed_data['sentry'][:project_id]
  }
  formatted_list << org_details
end

formatted_list.to_csv
puts "Finished scraping. #{companies.length} companies scraped."



