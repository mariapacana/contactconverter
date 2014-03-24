require 'csv'
require 'yaml'
require 'pry'
require 'rspec'

require_relative 'util'
require_relative 'row'
require_relative 'constants'
require_relative 'header'
require_relative 'contact_csv'

class ContactList

  attr_accessor :contacts, :config
  attr_reader :not_google

  include Util
  include Row
  include Constants
  include Header
  include ContactCSV

  def initialize(args)
    if args[:config_file].nil?
      @contacts = CSV.read(args[:source_file], headers: true)
    else
      change_headers = lambda do |header|
        header = @config[header].nil? ? header : @config[header]
      end
      @not_google = true
      @config = YAML.load(File.open(args[:config_file])) 
      @contacts = CSV.read(args[:source_file], 
                                headers: true, 
                                header_converters: change_headers)
      @contacts = Header.headers_in_order(@contacts)
    end
  end

  def headers
    @contacts.headers
  end

  def delete_blank_columns
    headers.each do |header|
      if @contacts[header].uniq.size < 3 && header != "Gender"
        @contacts.delete(header)
      end
    end
  end

  def save_to_file(filename)
    CSV.open(filename, "wb") do |csv|
      csv << headers
      @contacts.each do |row|
        csv << row
      end
    end
  end

  def format_list
    process_fields
    remove_sparse_contacts
  end

  def remove_duplicate_contacts(field)
    field_hash = make_frequency_hash(field)
    field_hash = pull_out_duplicates(field, field_hash)
    strip_duplicate_entries(field_hash) #deletes dups from main
    save_to_file("icloud_no_#{field}_dups.csv")
    field_hash
  end

  def process_duplicate_contacts(field_hash)
    contacts_arry = remove_contact_dups(field_hash)
    table = convert_contact_arry_to_csv(contacts_arry)
    reprocess_row_dups(table)

    table.headers.each do |header|
      if table[header].uniq.size < 3 && header != "Gender"
        table.delete(header)
      end
    end

    CSV.open("icloud_#{field}_duplicates.csv", "wb") do |csv|
      csv << table.headers
      table.each { |row| csv << row }
    end
  end

  def remove_contact_dups(email_hash)
    contacts_arry = []
    email_hash.each do |email, contact_table|
      new_contact = {}
      remove_field_dups(PHONES, contact_table, new_contact)
      remove_field_dups(EMAILS, contact_table, new_contact)
      remove_field_dups(WEBSITES, contact_table, new_contact)

      remove_name_dups(contact_table, new_contact)
      remove_address_dups(contact_table, new_contact)

      UNIQUE_HEADERS.each do |header|
        new_contact[header] = contact_table[header].uniq.join("\n")
      end
      contacts_arry << new_contact
    end
    contacts_arry
  end

  def convert_contact_arry_to_csv(contacts_arry)
    rows = []
    contacts_arry.each do |contact|
      field_arry = []
      headers.each do |header|
        field_arry << contact[header] || nil
      end
      rows << CSV::Row.new(headers, field_arry)
    end
    table = CSV::Table.new(rows)
  end

  def remove_address_dups(contact_table, new_contact)
    addy_map = get_unique_address_vals(contact_table)
    STRUC_ADDRESSES.each do |address, values|
      addy = addy_map.shift unless Util.nil_or_empty?(addy_map)
      values.each do |value|
        new_contact[value] = addy.shift unless Util.nil_or_empty?(addy)
      end
    end
  end

  def get_unique_address_vals(contact_table)
    address_hash = get_address_hash(contact_table)
    address_map = address_mapping(address_hash)
    address_map = get_unique_addresses(address_map)
  end

  def remove_name_dups(contact_table, new_contact)
    name_hash = {}
    NAMES.each do |name_type|
      name_hash[name_type] = contact_table[name_type].uniq
    end
    NAMES.each do |name_type|
      new_contact[name_type] = name_hash[name_type].join("\n")
    end
  end

  def get_address_hash(contact_table)
    address_hash = {}
    ADDRESSES.each do |type, vals|
      new_arry = []
      contact_table.each do |row|
        if new_arry.empty?
          new_arry = vals.map {|val| row[val]}
        else
          new_arry = new_arry + vals.map {|val| row[val]}
        end
     end
      address_hash[type] = new_arry
    end
    address_hash
  end

  def address_mapping(address_hash)
    length = address_hash[address_hash.keys.first].length
    address_mapping = {}
    (0..length-1).each do |num|
      arry = []
      address_hash.each do |type, vals|
        arry << address_hash[type][num]
      end
      address_mapping[address_hash["street"][num]] = arry
    end
    address_mapping
  end

  def get_unique_addresses(address_map)
    address_arry = []
    keys = address_map.keys.uniq.select {|key| key != nil && key != "" }
    address_map.each do |key, value| 
      address_arry << value if keys.include?(key) 
    end
    address_arry
  end

  def get_unique_field_vals(val_type_hash, contact)
    val_type_hash.map do |val, type|
      contact[val].zip(contact[type]).select do |a| 
        !(Util.nil_or_empty?(a[0]) && Util.nil_or_empty?(a[1]))
      end
    end.reduce(:+).uniq
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

  private
    def process_fields
      @contacts.each do |contact|
        Row.get_phone_types(contact) if @not_google
        Row.standardize_phones(contact, FIELDS["phones"]["value"])
        Row.remove_duplicates(STRUC_EMAILS, contact)
        Row.remove_duplicates(STRUC_WEBSITES, contact)
        Row.remove_duplicates(STRUC_PHONES, contact)
        Row.remove_duplicates(STRUC_ADDRESSES, contact)
        Row.delete_invalid_names(contact)
        Row.move_contact_name(contact)
        Row.make_name(contact)
      end
    end

    def remove_sparse_contacts
      new_contacts = @contacts.select {|c| Row.enough_contact_info(c) }
      @contacts = CSV::Table.new(new_contacts)
    end

    def make_frequency_hash(field)
      field_hash = {}
      @contacts.each do |contact|
        if !(field_hash[contact[field]].nil?)
          field_hash[contact[field]] = field_hash[contact[field]] << contact
        else
          field_hash[contact[field]] = CSV::Table.new([contact])
        end
      end
      field_hash
    end

    def pull_out_duplicates(field, field_hash)
      field_hash.select do |field_val, contact|
        contact.size > 1 && !Util.nil_or_empty?(field_val) && ContactCSV.similarity_tests(field, COMPARISON[field], contact)
      end
    end

    def strip_duplicate_entries(field_hash)
      ids = field_hash.values.map {|c| c["IC - id"]}.flatten
      new_contacts = @contacts.select {|c| !(ids.include?(c["IC - id"])) }
      @contacts = CSV::Table.new(new_contacts)
    end
end