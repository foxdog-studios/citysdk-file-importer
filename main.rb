require 'json'
require 'logger'

require 'citysdk'
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

  api = CitySDK::API.new(url)
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
  builder = CitySDK::NodeBuilder.new

  case opts[:type]
  when 'json'
    builder.load_data_set_from_json!(opts.fetch(:input))
    builder.set_geometry_from_lat_lon!('lat', 'lon')
  when 'zip'
    builder.load_data_set_from_zip!(opts.fetch(:input))
  when 'kml'
    builder.load_data_set_from_kml!(opts.fetch(:input))
  end

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
  nodes = builder.build

  logger.info('Creating nodes through the CitySDK API')
  api.create_nodes(layer, nodes)
  return 0
end


def parse_options
  opts = Trollop::options do
    opt(:type        , "One of: #{DATA_TYPES.join(', ')}", type: :string)
    opt(:category    , 'Layer category'      , type: :string)
    opt(:config      , 'Configuration file'  , type: :string)
    opt(:description , 'Layer description'   , type: :string)
    opt(:input       , 'Input file to import', type: :string, required: true)
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

  unless opts[:config].nil?
    config = open(opts.fetch(:config)) do |config_file|
      JSON.load(config_file, nil, symbolize_names: true)
    end # do
    opts = opts.merge(config)
  end # unless

  required = [
    :category,
    :description,
    :layer,
    :organization,
    :password,
    :url,
    :email,
    :type
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

