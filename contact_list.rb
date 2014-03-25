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
  attr_reader :source_type

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
      @config = YAML.load(File.open(args[:config_file])) 
      @contacts = CSV.read(args[:source_file], 
                                headers: true, 
                                header_converters: change_headers)
      @contacts = Header.headers_in_order(@contacts)
      set_source_type(args[:source_file])
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
    field_hash = make_field_hash(field)
    extract_duplicates!(field, field_hash)
    delete_dups_from_contacts!(field_hash)
    save_to_file("#{@source_type}_no_#{field}_dups.csv")
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

    CSV.open("#{@source_type}_#{field}_duplicates.csv", "wb") do |csv|
      csv << table.headers
      table.each { |row| csv << row }
    end
  end

  def remove_contact_dups(field_hash)
    contacts_arry = []
    field_hash.each do |email, contact_table|
      new_contact = {}
      remove_field_dups(STRUC_PHONES, contact_table, new_contact)
      remove_field_dups(STRUC_EMAILS, contact_table, new_contact)
      remove_field_dups(STRUC_WEBSITES, contact_table, new_contact)
      remove_field_dups(STRUC_ADDRESSES, contact_table, new_contact)
      #and remove name dups

      UNIQUE_HEADERS.each do |header|
        new_contact[header] = contact_table[header].uniq.join("\n")
      end
      contacts_arry << new_contact
    end
    contacts_arry
  end

  def get_hash(struc_fields, contact_table)
    field_hash = {}
    struc_fields.each do |field, subfields|
      subfield_type_vals = subfields.map {|f| contact_table[f]}
      num_val_sets = subfield_type_vals[0].length
      (0..num_val_sets-1).each do |num|
        vals = subfield_type_vals.map {|s| s[num] }[1..-1]
        type = subfield_type_vals[0][num]
        if Row.field_not_empty?(vals)
          if !field_hash.has_key?(vals)
            field_hash[vals] = [type]
          else
            field_hash[vals] << type
          end
        end
      end
    end
    Util.join_hash_values(field_hash)
  end

  def remove_field_dups(struc_fields, contact_table, new_contact)
    field_hash = get_hash(struc_fields, contact_table)
    Row.set_fields(struc_fields, field_hash, new_contact)
  end

  private
    def set_source_type(source_file)
      if source_file.scan(/icloud/)
          @source_type = "icloud"
      elsif source_file.scan(/cardscan/)
        @source_type = "cardscan"
      elsif source_file.scan(/sageact/)
        @source_type = "sageact"
      else
        @source_type = "google"
      end
    end

    def source_file_not_google
      @source_type != "google"
    end

    def process_fields
      @contacts.each do |contact|
        Row.get_phone_types(contact) if source_file_not_google
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

    def make_field_hash(field)
      field_hash = {}
      @contacts.each do |contact|
        if !(field_hash[contact[field]].nil?)
          field_hash[contact[field]] << contact
        else
          field_hash[contact[field]] = CSV::Table.new([contact])
        end
      end
      field_hash
    end

    def extract_duplicates!(field, field_hash)
      field_hash.select! do |field_val, contact|
        contact.size > 1 && !Util.nil_or_empty?(field_val) && ContactCSV.similarity_tests(field, COMPARISON[field], contact)
      end
    end

    def delete_dups_from_contacts!(field_hash)
      ids = field_hash.values.map {|c| c["IC - id"]}.flatten
      new_contacts = @contacts.select {|c| !(ids.include?(c["IC - id"])) }
      @contacts = CSV::Table.new(new_contacts)
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
end