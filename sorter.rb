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
    addresses = address_array.map {|a| contact[a]}
    new_street_vals = addresses.map {|a| self.return_address(contact, type, a)} << contact[self.full_address(type, "Street")]
    new_vals =  new_street_vals.select! {|val| !Util.nil_or_empty?(val)}.uniq
    contact[self.full_address(type, "Street")] = new_vals.join("\n")
  end

  def self.should_print(contact, type, address)
    !self.fix_address_field(contact, type, address) && !Util.nil_or_empty?(address)
  end

  def self.return_address(contact, type, address)
    self.should_print(contact, type, address) ? address : nil
  end

  def self.fix_address_field(contact, type, address_field)
    reg = {street: "(?<street>[\\d\\-]+\\s*[\\da-zA-Z]+\\s*[a-zA-Z.]+\\s(Ave.|Avenue|Rd.|Road|Street|Way|Lane|Ct.|Court|Circle))",
           city: "(?<city>[a-zA-Z\\s]*)",
           po_box: "(?<pobox>P\\.?O\\.?\\s*[Bb]ox\\s*\\d{1,6})",
           region: "(?<region>[a-zA-Z]{1}\\.?[a-zA-Z]{1}\\.?)",
           zip: "(?<zip>\\d{5}-\\d{4}|\\d{5}|[\\dA-Z]{5})"}
    if !Util.nil_or_empty?(address_field)
      address_field = address_field.gsub("\\n", "\n")
      if data = address_field.match(/\A[\s\n]*#{reg[:street]}[,\s\n]+#{reg[:city]}[,\s\n]+#{reg[:region]}[,\s]+#{reg[:zip]}.*\z/)
        self.save_address_field(contact, self.full_address(type, "Street"), data["street"])
        self.save_address_field(contact, self.full_address(type, "City"), data["city"])
        self.save_address_field(contact, self.full_address(type, "Region"), data["region"])
        self.save_address_field(contact, self.full_address(type, "Postal Code"), data["zip"])
        return true
      elsif data = address_field.match(/\A[\s\n]*#{reg[:street]}[\s\n]*\z/)
        self.save_address_field(contact, self.full_address(type, "Street"), data["street"])
        return true
      elsif data = address_field.match(/\A\s*#{reg[:zip]}\s*\z/)
        self.save_address_field(contact, self.full_address(type, "Postal Code"), data["zip"])
        return true
      elsif data = address_field.match(/\A[\s\n]*#{reg[:city]}[,\s]+#{reg[:region]}[,\s]+#{reg[:zip]}.*\z/)
        self.save_address_field(contact, self.full_address(type, "City"), data["city"])
        self.save_address_field(contact, self.full_address(type, "Region"), data["region"])
        self.save_address_field(contact, self.full_address(type, "Postal Code"), data["zip"])
        return true
      elsif data = address_field.match(/\A[\s\n]*#{reg[:po_box]}[\s\n]*\z/)
        self.save_address_field(contact, self.full_address(type, "PO Box"), data["pobox"])
        return true
      elsif data = address_field.match(/\A[\s\n]*#{reg[:po_box]}[\s\n]*#{reg[:street]}[,\s\n]*\z/)
        self.save_address_field(contact, self.full_address(type, "PO Box"), data["pobox"])
        self.save_address_field(contact, self.full_address(type, "Street"), data["street"])
        return true
      elsif data = address_field.match(/\A(?<pobox>P\.?O\.?\s*[Bb]ox\s*\d{1,10})[,\s]+#{reg[:city]}[,\s]+#{reg[:region]}[,\s]+#{reg[:zip]}\z/)
        self.save_address_field(contact, self.full_address(type, "PO Box"), data["pobox"])
        self.save_address_field(contact, self.full_address(type, "City"), data["city"])
        self.save_address_field(contact, self.full_address(type, "Region"), data["region"])
        self.save_address_field(contact, self.full_address(type, "Postal Code"), data["zip"])
        return true
      end
    end
    return false
  end

  def self.full_address(address_type, field_type)
    if address_type == "home"
      "Address 2 - #{field_type}"
    elsif address_type == "work"
      "Address 1 - #{field_type}"
    else
      "Address 3 - #{field_type}"
    end
  end

  def self.save_address_field(contact, full_address_field, value)
    Util.set_value_if_nil(contact, full_address_field, value)
  end

  def self.save_address_field_force(contact, address_type, field_type, value)

  end

end