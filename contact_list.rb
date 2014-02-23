require 'csv'
require 'yaml'
require 'pry'

require File.expand_path('../phone.rb', __FILE__)

class ContactList

  attr_accessor :contacts, :config

  include Phone

  FIELDS = YAML.load(File.open('google.yaml'))

  def initialize(args)

    change_headers = lambda do |header|
      header = @config[header].nil? ? header : @config[header]
    end

    @config = YAML.load(File.open(args[:config_file]))

    if args[:config_file].nil?
      @contacts = CSV.read(args[:source_file], headers: true)
    else
      @contacts = CSV.read(args[:source_file], 
                                headers: true, 
                                header_converters: change_headers)
    end

  end

  def headers
    @contacts.headers
  end

  def num_headers
    @contacts.headers.size
  end

  def delete_blank_columns
    headers.each do |header|
      if @contacts[header].uniq.size < 3 && header != "Gender"
        @contacts.delete(header)
      end
    end
  end

  def flag_sparse_columns
    headers.each do |header|
      if @contacts[header].uniq.size < 20
        puts "header: #{header}, values: #{@contacts[header].uniq }"
      end
    end
  end

  def save_to_file(filename)
    File.open(filename, 'w') {|f| f.write(@contacts.to_s) }
  end

  def include_columns(type)
    FIELDS[type].each { |col| @contacts[col] = nil }
  end

  def process_phones
    include_columns("phones")
    @contacts.each do |person|
      Phone.get_phone_types(person)
      Phone.standardize_phones(person, FIELDS["phones"]["value"])
    end
  end

end


class CSV::Row

  def has_field?(header)
    ! (field(header).nil? || field(header).empty?)
  end

end