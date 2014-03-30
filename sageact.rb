require_relative 'util'
require_relative 'constants'

require 'pry'

module Sageact

  include Util
  include Constants

  def self.address_type(field)
    SA_ADDRESSES[field]
  end

  def self.sort_addresses(contact)
    SA_STRUC_ADDRESSES.each do |type, array|
      self.sort_address(type, array, contact)
    end
  end

  def self.sort_address(type, address_array, contact)
    if !Util.nil_or_empty?(contact[address_array[1]])
      if data = contact[address_array[1]].match(/(?<zip>\d{5}-\d{4}|\d{5})/)
        self.save_address_field(contact, type, "Postal Code", data["zip"])
      elsif data = address_array[1].match(/(?<city>.*)[,\s]?(?<region>[a-zA-Z]{1}\.?[a-zA-Z]{1}\.?)[\s]?(?<zip>\d{5}-\d{4}|\d{5})$/)
        binding.pry
        self.save_address_field(contact, type, "City", data["zip"])
        self.save_address_field(contact, type, "Region", data["region"])
        self.save_address_field(contact, type, "Postal Code", data["zip"])
      # else
      #   self.merge_address_fields(contact[address_array[1]])
      end
    end
  end

  def self.save_address_field(contact, address_type, field_type, value)
    if address_type == "home"
      Util.set_value_if_nil(contact, "Address 2 - #{field_type}", value)
    elsif address_type == "work"
      Util.set_value_if_nil(contact, "Address 1 - #{field_type}", value)
    else
      Util.set_value_if_nil(contact, "Address 3 - #{field_type}", value)
    end
  end

  

end