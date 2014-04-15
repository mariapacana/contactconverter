require_relative 'constants'
require_relative 'util'

module Header

  include Constants
  include Util

  def self.headers_in_order(contacts, source_type)
    new_headers = self.delete_nil_headers(contacts)
    new_headers = self.update_headers(contacts, source_type)
    self.add_missing_headers(new_headers, contacts)
  end

  def self.non_google_headers(contacts, source_type)
    headers = contacts.headers - G_HEADERS
    source_type == "icloud" ? headers - ["ID"] : headers
  end

  def self.update_headers(contacts, source_type)
    ["ID"] + G_HEADERS - ["Notes"] + self.non_google_headers(contacts, source_type) + ["Notes"]
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

  def self.delete_nil_headers(contacts)
    contacts.headers.select {|h| !Util.nil_or_empty? contacts[h]}
  end


end