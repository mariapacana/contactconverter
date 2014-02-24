require 'csv'
require 'yaml'
require 'pry'

require File.expand_path('../phone.rb', __FILE__)
require File.expand_path('../row.rb', __FILE__)
require File.expand_path('../column.rb', __FILE__)

class ContactList

  attr_accessor :contacts, :config
  attr_reader :not_google

  include Phone
  include Row
  include Column

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

  def include_columns(field, sub_field)
    FIELDS[field][sub_field].each { |col| @contacts[col] = nil }
  end

  def process_phones
    include_columns("phones", "type")
    @contacts.each do |contact|
      Phone.get_phone_types(contact) if @not_google
      Phone.standardize_phones(contact, FIELDS["phones"]["value"])
    end
  end

  def process_fields
    emails = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
    websites = Hash[FIELDS["websites"]["value"].zip(FIELDS["websites"]["type"])]
    phones = Hash[FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"])]

    @contacts.each do |contact|
      Row.remove_duplicates(emails, contact)
      Row.remove_duplicates(websites, contact)
      Row.remove_duplicates(phones, contact)
    end
  end

  def make_email_array
    email_hash = {}
    @contacts.each do |contact|
      first_email = contact[FIELDS["emails"]["value"][0]]
      if email_hash[first_email]
        email_hash[first_email] = email_hash[first_email] << contact
      else
        email_hash[first_email] = [contact]
      end
    end
    email_hash.select! {|key, value| value.size > 1}
  end

  def eliminate_dups(contact_ary)
    contact_hash = {}
    contact_ary.each do |contact|
      headers.each do |header|
        if contact_hash[header] 
          contact_hash[header] << contact[header]
        else
          contact_hash[header] = [contact[header]]
        end
      end
    end
    contact_hash.each do |field, value|
      contact_hash[field] = value.uniq
    end
    contact_hash
  end
end

class CSV::Row

  def has_field?(header)
    ! (field(header).nil? || field(header).empty?)
  end

end