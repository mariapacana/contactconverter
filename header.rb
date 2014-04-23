require_relative 'constants'
require_relative 'util'

module Header

  include Constants
  include Util

  def self.change_headers(header, config, source_type)
    config[header].nil? ? "#{SHORTNAMES[source_type]} - #{header}" : config[header]
  end

  def self.headers_in_order(contacts, source_type)
    new_headers = self.delete_nil_headers(contacts)
    new_headers = self.update_ordered_headers(new_headers, source_type)
    self.add_missing_headers(new_headers, contacts)
  end

  def self.delete_nil_headers(contacts)
    contacts.headers.select {|h| !Util.nil_or_empty? contacts[h]}
  end

  def self.update_ordered_headers(headers, source_type)
    ["ID"] + self.google_then_non_google_no_id_notes(headers, source_type) + ["Notes"]
  end

  def self.non_google_headers(headers, source_type)
    headers = headers - G_HEADERS
  end

  def self.google_then_non_google_no_id_notes(headers, source_type)
    new_headers = G_HEADERS + self.non_google_headers(headers, source_type)
    new_headers.delete_if {|h| h == "Notes" || h == "ID"}
  end

  def self.add_missing_headers(headers, contacts)
    new_contacts = contacts.map do |contact|
      CSV::Row.new(headers,
                   self.row_data_with_new_headers(headers, contact))
    end
    CSV::Table.new(new_contacts)
  end

  def self.row_data_with_new_headers(updated_headers, contact)
    updated_headers.map do |header|
      !Util.nil_or_empty?(contact[header]) ? contact[header] : nil
    end
  end

end