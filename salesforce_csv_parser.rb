require 'csv'
require './salesforce_account.rb'

class SalesforceCSVParser
	attr_reader :csv_file

	def initialize(csv_file)
		@csv_file = csv_file
	end

	def company_data
		salesforce_accounts = []
		@raw_data = CSV.foreach(csv_file, headers: true, liberal_parsing: true) do |row|
			##### Coming from salesforce
			# details = {
			# 	name: row['Account Name'],
			# 	segment: row['Account Segment'],
			# 	website: website(row['Website']),
			# 	total_touch_arr: row['Total Touch ARR'],
			# 	id: row['Account ID'],
			# 	owner: row['Account Owner']
			# }
			####### coming from outputted results from dogwalk (i.e. rerun dogwalk on output)
			####### At this point after the first major run, I'm just doing reruns to hone in
			####### and increase accuracy. So these column names are more relevant. Keeping the above
			####### commented out til next time I need to run against a raw Salesforce export.
			####### Or could just rename the columns from the raw Salesforce report to match the below *shrug*
			details = {
				name: row['company'],
				segment: row['account_segment'],
				website: website(row['website']),
				total_touch_arr: row['total_touch_arr'],
				id: row['account_id'],
				owner: row['account_owner']
			}
			account = SalesforceAccount.new(
				details
			)
			salesforce_accounts << account
		end
		salesforce_accounts
	end

	def website(url)
		url.include?("http") ? url : "http://" + url
	end
end