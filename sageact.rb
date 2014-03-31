require_relative 'util'
require_relative 'constants'

require 'pry'

module Sageact

  include Util
  include Constants

  def self.sort_addresses(contact)
    SA_STRUC_ADDRESSES.each do |type, array|
      self.sort_address(contact, type, array)
    end
  end

  def self.sort_address(contact, type, address_array)
    address_1 = contact[address_array[0]]
    address_2 = contact[address_array[1]]
    address_3 = contact[address_array[2]]

    if !Util.nil_or_empty?(address_2) && !Util.nil_or_empty?(address_3) && !Util.nil_or_empty?(address_1)
      fixed2 = self.fix_address_field(contact, type, address_1, address_2)
      fixed3 = self.fix_address_field(contact, type, address_1, address_3)
      new_field = "#{address_1}#{"\n"+address_2 if !fixed2}#{"\n"+address_3 if !fixed3}"
      self.save_address_field(contact, type, "Street", new_field)
    elsif !Util.nil_or_empty?(address_2) && !Util.nil_or_empty?(address_1) && Util.nil_or_empty?(address_3)
      fixed = self.fix_address_field(contact, type, address_1, address_2)
      self.save_address_field(contact, type, "Street", "#{address_1}#{"\n"+address_2 if !fixed}")
    elsif !Util.nil_or_empty?(address_3) && !Util.nil_or_empty?(address_1) && Util.nil_or_empty?(address_2)
      fixed = self.fix_address_field(contact, type, address_1, address_3)
      self.save_address_field(contact, type, "Street", "#{address_1}#{"\n"+address_3 if !fixed}")
    elsif !Util.nil_or_empty?(address_1) && Util.nil_or_empty?(address_2) && Util.nil_or_empty?(address_3)
      self.save_address_field(contact, type, "Street", address_1)
    end
  end

  def self.fix_address_field(contact, type, address_1, address_field)
    if !Util.nil_or_empty?(address_field)
      if data = address_field.match(/^\s*(?<zip>\d{5}-\d{4}|\d{5})\s*$/)
        self.save_address_field(contact, type, "Postal Code", data["zip"])
        return true
      elsif data = address_field.match(/^(?<city>[a-zA-Z\s]*)[,\s]+(?<region>[a-zA-Z]{1}\.?[a-zA-Z]{1}\.?)[,\s]+(?<zip>\d{5}-\d{4}|\d{5})$/)
        self.save_address_field(contact, type, "City", data["city"])
        self.save_address_field(contact, type, "Region", data["region"])
        self.save_address_field(contact, type, "Postal Code", data["zip"])
        return true
      elsif data = address_field.match(/^(?<pobox>P\.?O\.?\s*[Bb]ox\s*\d{3,4})\s*$/)
        self.save_address_field(contact, type, "PO Box", data["pobox"])
        return true
      elsif data = address_field.match(/^(?<pobox>P\.?O\.?\s*[Bb]ox\s*\d{1,10})[,\s]+(?<city>[a-zA-Z]*)[,\s]+(?<region>[a-zA-Z]{1}\.?[a-zA-Z]{1}\.?)[,\s]+(?<zip>\d{5}-\d{4}|\d{5})$/)
        self.save_address_field(contact, type, "PO Box", data["pobox"])
        self.save_address_field(contact, type, "City", data["city"])
        self.save_address_field(contact, type, "Region", data["region"])
        self.save_address_field(contact, type, "Postal Code", data["zip"])
        return true
      end
    end
    return false
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