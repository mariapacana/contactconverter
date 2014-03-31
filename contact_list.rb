require 'csv'
require 'yaml'
require 'pry'
require 'rspec'

require_relative 'util'
require_relative 'row'
require_relative 'column'
require_relative 'constants'
require_relative 'header'
require_relative 'sageact'
require_relative 'contact_csv'

class ContactList

  attr_accessor :contacts, :config
  attr_reader :source_type

  include Util
  include Row
  include Constants
  include Header
  include ContactCSV
  include Sageact

  def initialize(args)
    if args[:config_file].nil?
      @contacts = CSV.read(args[:source_file], headers: true)
    else
      set_source_type(args[:source_file])
      change_headers = lambda do |header|
        header = @config[header].nil? ? "#{SHORTNAMES[@source_type]} - #{header}" : @config[header]
      end
      @config = YAML.load(File.open(args[:config_file])) 
      @contacts = CSV.read(args[:source_file], 
                                headers: true, 
                                header_converters: change_headers)
      delete_blank_non_google_columns
      @contacts = Header.headers_in_order(@contacts)
    end
  end

  def headers
    @contacts.headers
  end

  def save_to_file(filename)
    CSV.open(filename, "wb") do |csv|
      csv << headers
      @contacts.each do |row|
        csv << row
      end
    end
  end

  def fix_sageact
    @contacts.each do |contact|
      Sageact.sort_addresses(contact)
      Sageact.sort_extensions(contact)
    end
    SA_STRUC_DELETE.each{|addy| @contacts.delete(addy)}
  end

  def format_list
    fix_sageact if @source_type == "sageact"
    process_fields
    remove_sparse_contacts
  end

  def remove_and_process_duplicate_contacts(field)
    raise(ArgumentError, "field must be a header") unless G_HEADERS.include?(field)
    field_hash = remove_duplicate_contacts(field)
    save_to_file("#{@source_type}_no_#{field}_dups.csv")
    Column.process_duplicate_contacts(field_hash, field)
  end

  def remove_duplicate_contacts(field)
    field_hash = make_field_hash(field)
    extract_duplicates!(field, field_hash)
    delete_dups_from_contacts!(field_hash)
    field_hash
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

    def source_file_not_google
      @source_type != "google"
    end

    def delete_blank_columns(my_headers)
      my_headers.each do |header|
        if @contacts[header].uniq.size < 3 && header != "Gender"
          @contacts.delete(header)
        end
      end
    end

    def delete_blank_non_google_columns
      my_headers = headers.select{|h| h.match(SHORTNAMES[@source_type])}
      delete_blank_columns(my_headers)
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
        Row.standardize_notes(contact)
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
end