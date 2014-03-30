require_relative 'constants'
require_relative 'util'

module Header

  include Constants
  include Util

  def self.non_google_headers(contacts)
    contacts.headers - G_HEADERS
  end

  def self.updated_headers(contacts)
    G_HEADERS - ["Notes"] + self.non_google_headers(contacts) + ["Notes"]
  end

  def self.add_missing_headers(updated_headers, contact)
    updated_headers.map do |header|
      !Util.nil_or_empty?(contact[header]) ? contact[header] : nil
    end
  end

  def self.delete_nil_headers(contacts)
    contacts.headers.select {|h| !Util.nil_or_empty? contacts[h]}
  end

  def self.headers_in_order(contacts)
    updated_headers = self.delete_nil_headers(contacts)
    updated_headers = self.updated_headers(contacts)
    new_contacts = contacts.map do |contact|
      CSV::Row.new(updated_headers,
                   self.add_missing_headers(updated_headers, contact))
    end
    CSV::Table.new(new_contacts)
  end
end