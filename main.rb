require 'logger'
require 'json'

require 'citysdk'
require 'trollop'

def parse_options
  opts = Trollop::options do
    opt(:config,
        'Configuration JSON file',
        :type => :string)
    opt(:username,
        'City SDK username',
        :type => :string)
    opt(:password,
        'City SDK password',
        :type => :string)
    opt(:host,
        'City SDK endpoint hostname',
        :type => :string)
    opt(:layer,
        'Layer name',
        :type => :string)
    opt(:description,
        'Layer description',
        :type => :string)
    opt(:organization,
        'Layer organization',
        :type => :string)
    opt(:category,
        'Layer category',
        :type => :string)
    opt(:input,
        'Input file to import',
        :type => :string,
        :required => true)
  end

  if opts[:config]
    config_file = opts[:config]
    config = JSON.parse(IO.read(config_file), {symbolize_names: true})
    opts = opts.merge(config)
  end

  [:username, :password, :host, :layer, :description, :organization,
   :category].each do |option|
    unless opts[option]
      Trollop::die option, 'must be specified.'
    end
  end

  opts
end

class CitySdkFileImporter
  def initialize(host, username, password, layer_name, layer_description,
                 layer_organization, layer_category)
    @host = host
    @username = username
    @password = password
    @layer_name = layer_name
    @layer_description = layer_description
    @layer_organization = layer_organization
    @layer_category = layer_category
  end

  def ensure_layer_exists()
    api = CitySDK::API.new(@host)
    unless api.authenticate(@username, @password)
      raise "Unable to authenticate user: #{@username} password #{@password}"
    end
    begin
      result = api.get("/layer/#{@layer_name}")
    rescue CitySDK::HostException
      api.put('/layers', {
        :data => {
          :name => @layer_name,
          :description => @layer_description,
          :organization => @layer_organization,
          :category => @layer_category
        }
      })
    ensure
      api.release
    end
  end

  def import_file(file_path)
    self.ensure_layer_exists()
    importer = CitySDK::Importer.new({
      :file_path => file_path,
      :host => @host,
      :email => @username,
      :passw => @password,
      :layername => @layer_name
    })
    importer.doImport
  end

end


def main
  opts = parse_options()
  file_importer = CitySdkFileImporter.new(
    opts[:host],
    opts[:username],
    opts[:password],
    opts[:layer],
    opts[:description],
    opts[:organization],
    opts[:category]
  )
  file_importer.import_file(opts[:input])
end


if __FILE__ == $0
  main()
end

