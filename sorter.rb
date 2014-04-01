require_relative 'util'
require_relative 'constants'

require 'pry'

module Sorter

  include Util
  include Constants

  def self.sort_extensions(contact, struc_extensions)
    struc_extensions.each do |ext, phone|
      unless ext == 'SA - Alternate Extension'
        contact[phone] = "#{contact[phone]} Extension: #{contact[ext]}" if !Util.nil_or_empty?(contact[ext])
      end
    end
    if !Util.nil_or_empty?(contact['SA - Alternate Phone'])
      if !Util.nil_or_empty?(contact['SA - Alternate Extension'])
        alternate = "#{contact['SA - Alternate Phone']} Extension: #{contact['SA - Alternate Extension']}"
      else
        alternate = contact['SA - Alternate Phone']
      end
      PHONES.keys.each do |phone_val|
        if Util.nil_or_empty?(contact[phone_val])
          contact[phone_val] = alternate
          return
        end
      end
    end
  end

  def self.sort_addresses(contact, struc_addresses)
    struc_addresses.each do |type, array|
      self.label_addresses(contact, type, array)
      self.sort_address(contact, type, array)
    end
  end

  def self.label_addresses(contact, type, array)
    if array.select{|field| !Util.nil_or_empty?(contact[field])}.size >= 1
      if type == "work"
        contact["Address 1 - Type"] = "Work" 
      elsif type == "home"
        contact["Address 2 - Type"] = "Home"
      else
        contact["Address 3 - Type"] = "Other"
      end
    end
  end

  def self.sort_address(contact, type, address_array)
    if address_array.size == 3
      self.sort_three_addresses(contact, type, address_array)
    elsif address_array.size == 2
      self.sort_two_addresses(contact, type, address_array)
    end
  end


  def self.sort_two_addresses(contact, type, address_array)
    address_1 = contact[address_array[0]]
    address_2 = contact[address_array[1]]

    fixed1 = self.fix_address_field(contact, type, address_1)
    fixed2 = self.fix_address_field(contact, type, address_2)
    self.save_address_field(contact, type, "Street", "#{address_1 if !fixed1 && !Util.nil_or_empty?(address_1)}#{"\n" + address_2 if !fixed2 && !Util.nil_or_empty?(address_2)}")
  end

  def self.sort_three_addresses(contact, type, address_array)
    address_1 = contact[address_array[0]]
    address_2 = contact[address_array[1]]
    address_3 = contact[address_array[2]]

    fixed1 = self.fix_address_field(contact, type, address_1)
    fixed2 = self.fix_address_field(contact, type, address_2)
    fixed3 = self.fix_address_field(contact, type, address_3)

    street = "#{address_1}"
    street += "#{"\n"+address_2}" if !fixed2 && !Util.nil_or_empty?(address_2)
    street += "#{"\n"+address_3}" if !fixed2 && !Util.nil_or_empty?(address_3)
    self.save_address_field(contact, type, "Street", street)
  end

  def self.fix_address_field(contact, type, address_field)
    if !Util.nil_or_empty?(address_field)
      if data = address_field.match(/^[\s]*(?<street>[\d\-]+\s*[\da-zA-Z]+\s*[a-zA-Z.]+\s(Ave.|Avenue|Rd.|Road|Street|Way|Lane|Ct.|Court|Circle))[,\s\n]+(?<city>[a-zA-Z\s]*)[,\s\n]+(?<region>[a-zA-Z]{1}\.?[a-zA-Z]{1}\.?)[,\s]+(?<zip>\d{5}-\d{4}|\d{5}).*$/)
        self.save_address_field(contact, type, "Street", data["street"])
        self.save_address_field(contact, type, "City", data["city"])
        self.save_address_field(contact, type, "Region", data["region"])
        self.save_address_field(contact, type, "Postal Code", data["zip"])
        return true
      elsif data = address_field.match(/^?(<street>[\d\-]+\s*[\da-zA-Z]+\s*[a-zA-Z.]+\s(Ave.|Avenue|Rd.|Road|Street|Way|Lane|Ct.|Court))[\s\n]*$/)
        self.save_address_field(contact, type, "Street", data["street"])
        return true
      elsif data = address_field.match(/^\s*(?<zip>\d{5}-\d{4}|\d{5})\s*$/)
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