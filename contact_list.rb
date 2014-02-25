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
  EMAILS = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
  WEBSITES = Hash[FIELDS["websites"]["value"].zip(FIELDS["websites"]["type"])]
  PHONES = Hash[FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"])]

  def initialize(args)

    change_headers = lambda do |header|
      header = @config[header].nil? ? header : @config[header]
    end

    if args[:config_file].nil?
      @contacts = CSV.read(args[:source_file], headers: true)
    else
      @not_google = true
      @config = YAML.load(File.open(args[:config_file])) 
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
    @contacts.each do |contact|
      Row.remove_duplicates(EMAILS, contact)
      Row.remove_duplicates(WEBSITES, contact)
      Row.remove_duplicates(PHONES, contact)
    end
  end

  def format_non_google_list
    process_phones
    process_fields
    delete_blank_columns
  end

  def make_email_array
    email_hash = {}
    @contacts.each do |contact|
      first_email = contact[FIELDS["emails"]["value"][0]]
      if !(email_hash[first_email].nil?)
        email_hash[first_email] = email_hash[first_email] << contact
      else
        email_hash[first_email] = CSV::Table.new([contact])
      end
    end
    email_hash.select! {|email, contact| contact.size > 1 && !email.nil? && !email.empty? }
  end

  def remove_contact_dups(email_hash)
    email_hash.each do |email, contact_table|
      new_contact = {}
      remove_field_dups(PHONES, contact_table, new_contact)
      remove_field_dups(EMAILS, contact_table, new_contact)
      remove_field_dups(WEBSITES, contact_table, new_contact)
      headers.each do |header|
        new_contact[header] = contact_table[header].join("\n") if !(new_contact[header])
      end
    end
  end

  def get_unique_field_vals(val_type_hash, contact)
    val_type_hash.map do |val, type|
      contact[val].zip(contact[type]).select do |a| 
        !((a[0].nil? || a[0].empty?) && (a[1].nil? || a[1].empty?))
      end
    end.reduce(:+)
  end

  def assign_values(val_type_hash, unique_values, new_contact)
    val_type_hash.each do |field_val, field_type|
      if !(unique_values.empty?)
        contact_val_type = unique_values.shift
        new_contact[field_val] = contact_val_type[0]
        new_contact[field_type] = contact_val_type[1]
      else
        new_contact[field_val] = nil
        new_contact[field_type] = nil
      end
    end
    new_contact
  end

  def remove_field_dups(val_type_hash, contact, new_contact)
    unique_values = get_unique_field_vals(val_type_hash, contact)
    assign_values(val_type_hash, unique_values, new_contact)
  end

end

class CSV::Row

  def has_field?(header)
    ! (field(header).nil? || field(header).empty?)
  end

end