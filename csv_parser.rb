# monkey-patch Array class.
# https://gist.github.com/christiangenco/8acebde2025bf0891987
class Array
  def to_csv(csv_filename="observed_list.csv")
    require 'csv'
    CSV.open(csv_filename, "wb") do |csv|
      csv << first.keys # adds the attributes name on the first line
      self.each do |hash|
        csv << hash.values
      end
    end
  end
end