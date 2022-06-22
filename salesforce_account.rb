class SalesforceAccount
	attr_reader :website, :name, :segment, :owner, :id, :total_touch_arr

	def initialize(opts = {})
		@name = opts[:name]
		@segment = opts[:segment]
		@owner = opts[:owner]
		@website = opts[:website]
		@id = opts[:id]
		@total_touch_arr = opts[:total_touch_arr]
	end
end