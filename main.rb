require 'json'
require 'logger'

require 'citysdk/client'
require 'faraday'
require 'trollop'

DATA_TYPES = [
  'json',
  'kml',
  'zip'
]

def main
  opts = parse_options()
  logger = Logger.new(STDOUT)

  url = opts.fetch(:url)
  email = opts.fetch(:email)
  password = opts.fetch(:password)

  conn = Faraday.new(url: url)
  api = CitySDK::API.new(conn)
  api.set_credentials(email, password)

  layer = opts.fetch(:layer)
  unless api.layer?(layer)
    logger.info("Creating layer: #{layer}, as it does not exist")
    api.create_layer(
      name:         layer,
      description:  opts.fetch(:description),
      organization: opts.fetch(:organization),
      category:     opts.fetch(:category)
    )
  end # unless

  logger.info("Loading nodes from #{opts.fetch(:input)}")

  dataset = CitySDK::Dataset.load_path(
    opts.fetch(:input),
    opts.fetch(:type).to_sym
  )

  builder = CitySDK::NodeBuilder.new(dataset)

  if opts.fetch(:type) == 'json'
    builder.set_geometry_from_lat_lon!('lat', 'lon')
  end # if

  unless opts[:id].nil?
    builder.set_node_id_from_value!(opts.fetch(:id))
  end

  unless opts[:name].nil?
    name = opts.fetch(:name)
    builder.set_node_name_from_value!(name)
    builder.set_node_data_from_key_value!('name', name)
  end

  unless opts[:id_field].nil?
    builder.set_node_id_from_data_field!(opts[:id_field])
  end

  unless opts[:name_field].nil?
    builder.set_node_name_from_data_field!(opts[:name_field])
  end

  logger.info('Building nodes')
  nodes = builder.nodes

  logger.info('Creating nodes through the CitySDK API')
  api.create_nodes(layer, nodes)
  return 0
rescue Faraday::Error::ConnectionFailed => connection_error
  puts "Could not connect to the API: #{connection_error.message}"
  return 1
end


def parse_options
  opts = Trollop::options do
    opt(:type        , "One of: #{DATA_TYPES.join(', ')}", type: :string)
    opt(:category    , 'Layer category'      , type: :string)
    opt(:config      , 'Configuration file'  , type: :string)
    opt(:description , 'Layer description'   , type: :string)
    opt(:input       , 'Input file to import', type: :string)
    opt(:layer       , 'Layer name'          , type: :string)
    opt(:organization, 'Layer organization'  , type: :string)
    opt(:password    , 'CitySDK password'    , type: :string)
    opt(:url         , 'CitySDK API base URL', type: :string)
    opt(:email       , 'CitySDK email'       , type: :string)
    opt(:id_field    , 'Field for id'        , type: :string)
    opt(:name_field  , 'Field for name'      , type: :string)
    opt(:id          , 'Id to use'           , type: :string)
    opt(:name        , 'Name to user'        , type: :string)
  end

  if opts[:config]
    config = open(opts.fetch(:config)) do |config_file|
      JSON.load(config_file, nil, symbolize_names: true)
    end # do
    opts = opts.merge(config)
  end # if

  required = [
    :category,
    :description,
    :layer,
    :organization,
    :password,
    :url,
    :email,
    :type,
    :input
  ]

  required.each do |opt|
    Trollop::die(opt, 'must be specified.') if opts[opt].nil?
  end # do

  unless DATA_TYPES.include? opts[:type]
    Trollop::die(:type, "must be one of #{DATA_TYPES.join(', ')}")
  end # unless

  opts
end


if __FILE__ == $0
  exit main
end

