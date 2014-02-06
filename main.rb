require 'json'

require 'citysdk'
require 'trollop'


def main
  opts = parse_options()
  url = opts.fetch(:url)
  email = opts.fetch(:email)
  password = opts.fetch(:password)

  api = CitySDK::API.new(url)
  api.set_credentials(email, password)

  layer = opts.fetch(:layer)
  unless api.layer?(layer)
    api.create_layer(
      name:         layer,
      description:  opts.fetch(:description),
      organization: opts.fetch(:organization),
      category:     opts.fetch(:category)
    )
  end # unless

  builder = CitySDK::NodeBuilder.new
  builder.load_data_set_from_json!(opts.fetch(:input))
  builder.set_geometry_from_lat_lon!('lat', 'lon')
  builder.set_node_id_from_data_field!('id')
  builder.set_node_name_from_data_field!('name')
  nodes = builder.build

  api.create_nodes(layer, nodes)
  return 0
end


def parse_options
  opts = Trollop::options do
    opt(:category    , 'Layer category'      , type: :string)
    opt(:config      , 'Configuration file'  , type: :string)
    opt(:description , 'Layer description'   , type: :string)
    opt(:input       , 'Input file to import', type: :string, required: true)
    opt(:layer       , 'Layer name'          , type: :string)
    opt(:organization, 'Layer organization'  , type: :string)
    opt(:password    , 'CitySDK password'    , type: :string)
    opt(:url         , 'CitySDK API base URL', type: :string)
    opt(:email       , 'CitySDK email'       , type: :string)
  end

  if opts.key?(:config)
    config = open(opts.fetch(:config)) do |config_file|
      JSON.load(config_file, nil, symbolize_names: true)
    end
    opts = opts.merge(config)
  end

  required = [
    :category,
    :description,
    :layer,
    :organization,
    :password,
    :url,
    :email
  ]

  required.each do |opt|
    Trollop::die(opt, 'must be specified.') if opts[opt].nil?
  end

  opts
end


if __FILE__ == $0
  exit main
end

