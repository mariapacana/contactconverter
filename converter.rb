require 'csv'
require 'yaml'
require 'pry'

class Contacts

  MISSING_COLS = ['Phone 1 - Type', 'Phone 2 - Type', 'Phone 3 - Type', 'Phone 4 - Type']

  attr_accessor :data, :config

  def initialize(args)

    change_headers = lambda do |header|
      header = @config[header].nil? ? header : @config[header]
    end

    @config = args[:config_file].nil? ? nil : YAML.load(File.open(args[:config_file]))

    if args[:config_file].nil?
      @data = CSV.read(args[:source_file], headers: true)
    else
      @data = CSV.read(args[:source_file], headers: true, header_converters: change_headers)
    end

    include_columns

  end

  def headers
    @data.headers
  end

  def num_headers
    @data.headers.size
  end

  def delete_blank_columns
    headers.each do |header|
      if @data[header].uniq.size < 3 && header != "Gender"
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

  def include_columns
    MISSING_COLS. each { |col| @data[col] = nil }
  end

  def get_phone_types
    @data.each do |person|
      person['Phone 2 - Type'] = 'mobile' if person['Phone 2 - Value'] 
      person['Phone 3 - Type'] = 'home' if person['Phone 3 - Value'] 
      person['Phone 4 - Type'] = 'pager' if person['Phone 4 - Value'] 

      if person['Phone 1 - Value'] == person['Phone 2 - Value']
        person['Phone 1 - Type'] = 'mobile'
      elsif person['Phone 1 - Value'] == person['Phone 3 - Value']
        person['Phone 1 - Type'] = 'home'
      elsif person['Phone 1 - Value'] == person['Phone 4 - Value']
        person['Phone 1 - Type'] = 'pager'
      end 

    end
  end

end