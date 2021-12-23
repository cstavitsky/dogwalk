require 'selenium-webdriver'
require 'pry'
require './observability_product_sniffer.rb'
require './yc_client.rb'
require './csv_parser.rb'

puts "Starting scraping."
companies = YCClient.company_data
# companies = companies[0...5] #truncate while i test if this works. remove line when running for real
problems_scraping = false
formatted_list = []
companies.each do |company|
  observability_products_detected = ObservabilityProductSniffer.new(company['website']).sniff
  if observability_products_detected.nil?
    puts "Could not detect observability for #{company['name']}"
    problems_scraping = true
    observability_products_detected = ''
  else
    observability_products_detected = observability_products_detected.empty? ? '' : observability_products_detected
  end
  
  org_details = {
    company: company['name'],
    website: company['website'],
    uses_sentry: observability_products_detected.include?('sentry'),
    observability_products_detected: observability_products_detected,
    description: company['one_liner'],
    location: company['location'],
    industries: company['industries'],
    top_company: company['top_company'],
    team_size: company['team_size'],
    problems_scraping: problems_scraping
  }
  formatted_list << org_details
end

formatted_list.to_csv
puts "Finished scraping. #{companies.length} companies scraped."



