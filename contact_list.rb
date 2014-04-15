require 'csv'
require 'yaml'
require 'pry'
require 'rspec'

require_relative 'util'
require_relative 'row'
require_relative 'column'
require_relative 'constants'
require_relative 'header'
require_relative 'sorter'
require_relative 'contact_csv'

class ContactList

  attr_accessor :contacts, :config
  attr_reader :source_type

  include Util
  include Row
  include Constants
  include Header
  include ContactCSV
  include Sorter

  def initialize(args)
    set_source_type(args[:source_file])

    if args[:config_file].nil?
      @contacts = CSV.read(args[:source_file], headers: true)
    else
      change_headers = lambda do |header|
        header = Header.change_headers(header, @config, @source_type)
      end
      @config = YAML.load(File.open(args[:config_file])) 
      @contacts = CSV.read(args[:source_file], 
                                headers: true, 
                                header_converters: change_headers)
      delete_blank_non_google_columns
      @contacts = Header.headers_in_order(@contacts, @source_type)
    end
  end

  def headers
    @contacts.headers
  end

  def size
    @contacts.size
  end

  def save_to_file(filename)
    CSV.open(filename, "wb") do |csv|
      csv << headers
      @contacts.each do |row|
        csv << row
      end
    end
  end

  def <<(other_contact_list)
    raise(TypeError, "argument must be a ContactList") unless other_contact_list.class == ContactList

    shared_headers = headers & other_contact_list.headers
    new_headers = headers + (other_contact_list.headers - shared_headers)
    new_headers = Header.update_ordered_headers(new_headers, @source_type)
    @contacts = Header.add_missing_headers(new_headers, @contacts)

    new_contacts = []
    other_contact_list.contacts.each do |contact|
      contact_arry = new_headers.map {|h| contact[h] || ""}
      new_contacts << CSV::Row.new(new_headers, contact_arry)
    end
    new_contacts.each {|row| @contacts << row}
    self
  end

  def format_list
    sort_address_fields if @source_type != "google"
    process_fields
    remove_sparse_contacts
  end

  def add_id_column
    id = 1
    @contacts.each do |contact|
      if Util.nil_or_empty?(contact["ID"])
        contact["ID"] = id.to_s
        id += 1
      end
    end
  end

  def remove_and_process_duplicate_contacts(field)
    raise(ArgumentError, "field must be a header") unless G_HEADERS.include?(field)
    field_hash = remove_duplicate_contacts(field)
    Column.process_duplicate_contacts(field_hash, field, @source_type, headers)
  end

  private
    def set_source_type(source_file)
      if source_file.match(/icloud/)
          @source_type = "icloud"
      elsif source_file.match(/cardscan/)
        @source_type = "cardscan"
      elsif source_file.match(/sageact/)
        @source_type = "sageact"
      else
        @source_type = "google"
      end
    end

    def delete_blank_non_google_columns
      delete_blank_columns(non_google_columns) if @source_type != "google"
    end

    def delete_blank_columns(my_headers)
      my_headers.each do |header|
        if @contacts[header].uniq.size < 3 && header != "Gender"
          @contacts.delete(header)
        end
      end
    end

    def non_google_columns
      headers.select{|h| h.match(SHORTNAMES[@source_type])}
    end

    def sort_address_fields
      @contacts.each do |contact|
        Sorter.sort_addresses(contact, STRUC[@source_type]["addresses"])
        Sorter.sort_extensions(contact, STRUC[@source_type]["extensions"]) if @source_type == "sageact"
      end
      headers_to_delete.each{|addy| @contacts.delete(addy)}
    end

    def headers_to_delete
      if @source_type != 'sageact'
        STRUC[@source_type]["addresses"].values.flatten
      elsif @source_type == 'sageact'
        STRUC[@source_type]["addresses"].values.flatten + SA_STRUC_EXTENSIONS.keys + ['SA - Alternate Phone']
      else
        raise(Error, 'this must be a non-google list')
      end
    end

    def process_fields
      @contacts.each do |contact|
        Row.strip_fields(contact)
        Row.get_phone_types(contact) if @source_type != "google"
        Row.standardize_google(STRUC_PHONES, contact) if @source_type == "google"
        Row.standardize_google(STRUC_ADDRESSES, contact) if @source_type == "google"
        Row.standardize_google(STRUC_EMAILS, contact) if @source_type == "google"
        Row.standardize_phones(contact, FIELDS["phones"]["value"])
        Row.delete_invalid_names(contact)
        Row.move_contact_name(contact)
        Row.make_name(contact)
        Row.standardize_notes(contact)
        Row.remove_duplicates(STRUC_EMAILS, contact)
        Row.remove_duplicates(STRUC_WEBSITES, contact)
        Row.remove_duplicates(STRUC_PHONES, contact)
        Row.remove_duplicates(STRUC_ADDRESSES, contact)
      end
    end

    def remove_sparse_contacts
      new_contacts = @contacts.select {|c| Row.enough_contact_info(c) }
      @contacts = CSV::Table.new(new_contacts)
    end

    def remove_duplicate_contacts(field)
      field_hash = make_field_hash(field)
      extract_duplicates!(field, field_hash)
      delete_dups_from_contacts!(field_hash)
      field_hash
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
      ids = field_hash.values.map {|c| c["ID"]}.flatten
      new_contacts = @contacts.select {|c| !(ids.include?(c["ID"])) }
      @contacts = CSV::Table.new(new_contacts)
    end
end