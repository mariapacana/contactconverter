require 'csv'
require 'yaml'
require 'pry'

require File.expand_path('../phone.rb', __FILE__)

class ContactList

  attr_accessor :contacts, :config
  attr_reader :not_google

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
      @not_google = true
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
    @contacts.each do |contact|
      Phone.get_phone_types(contact) if @not_google
      Phone.standardize_phones(contact, FIELDS["phones"]["value"])
    end
  end

  def process_fields
    @contacts.each do |contact|
      emails = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
      contact_emails = {}

      emails.each do |email_val, email_type|
        contact_emails[contact[email_val]] = contact[email_type]
      end

      unique_email_vals = contact_emails.keys.uniq.select {|email| email != nil && email != ""}

      emails.each do |email_val, email_type|
        if !(unique_email_vals.empty?)
          email_val = unique_email_vals.shift
          contact[email_val] = email_val
          contact[email_type] = contact_emails[email_val]
        else
          contact[email_val] = nil
          contact[email_type] = nil
        end
      end

    end
  end
end

class CSV::Row

  def has_field?(header)
    ! (field(header).nil? || field(header).empty?)
  end

end