require 'net/http'

class YCClient
  class << self
    def company_data
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      content = request_body
      res = http.post(
        uri.path,
        JSON.dump(content),
        'Content-type' => 'application/json',
        'Accept' => 'text/json, application/json',
        'x-algolia-api-key' => 'algolia api key goes here',
        'x-algolia-application-id' => 'application id goes here'
      )

      #TODO: the api response is paginated. It would probably be wise to loop through and fetch all results.

      data = JSON.parse(res.body)['results'][0]
      data['hits']
    end

    def request_body
      "paste query params here"
    end

    def url
      "paste algolia url here"
    end
  end
end
