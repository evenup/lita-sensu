class SensuApi

  attr_reader :http, :config

  def initalize(http, config)
    @http = http
    @config = config
  end

end