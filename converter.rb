require 'csv'
require 'yaml'
require 'pry'

class Contacts

  attr_accessor :data, :config

  def initialize(source_file, config_file)
    cardscan = lambda do |header|
      header = @config[header].nil? ? header : @config[header]
    end

    @config = YAML.load(File.open(config_file))
    @data = CSV.read(source_file, headers: true, header_converters: cardscan)

  end

  def headers
    @data.headers
  end

  def num_headers
    @data.headers.size
  end

  def delete_blank_columns
    headers.each do |header|
      if @data[header].uniq == [nil]
        @data.delete(header)
      end
    end
  end

  def flag_sparse_columns
    headers.each do |header|
      if @data[header].uniq.size < 20
        puts "header: #{header}, values: #{@data[header].uniq }"
      end
    end
  end

  def save_to_file(filename)
    File.open(filename, 'w') {|f| f.write(@data.to_s) }
  end

end