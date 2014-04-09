require_relative 'util'
require_relative 'constants'

require 'pry'

module Row

  include Util
  include Constants

  def self.get_phone_types(contact)
    contact['Phone 2 - Type'] = 'mobile' if contact.has_field?('Phone 2 - Value')
    contact['Phone 3 - Type'] = 'home' if contact.has_field?('Phone 3 - Value')
    contact['Phone 4 - Type'] = 'pager' if contact.has_field?('Phone 4 - Value')
    contact['Phone 5 - Type'] = 'fax' if contact.has_field?('Phone 5 - Value')

    if !Util.nil_or_empty?(contact['Phone 1 - Value'])
      if contact['Phone 1 - Value'] == contact['Phone 2 - Value']
        contact['Phone 1 - Type'] = 'mobile'
      elsif contact['Phone 1 - Value'] == contact['Phone 3 - Value']
        contact['Phone 1 - Type'] = 'home'
      elsif contact['Phone 1 - Value'] == contact['Phone 4 - Value']
        contact['Phone 1 - Type'] = 'pager'
      end
    end
  end

  def self.standardize_phones(contact, fields)
    fields.each do |field|
      phone = contact[field]
      if !Util.nil_or_empty?(phone)
        phone.gsub!(/(\D)/,"")
        if phone.length == 11
          phone.insert(0, '+')
        elsif phone.length == 10
          phone.insert(0, '+1') 
        end
        contact[field] = phone
      end
    end
  end

  ## Had to replace \\n with \n.\. If we decide to save the data,
  ## will have to use String#scan.
  def self.standardize_notes(contact)
    cardscan_regexp = /^(#{ALL_CARDSCAN_FIELDS.join("|")}):\s.*$/
    if !Util.nil_or_empty?(contact["Notes"])  
      contact["Notes"] = contact["Notes"].gsub(/\\n/, "\n").gsub(cardscan_regexp, "").gsub(/\n+/, "\n").strip.split("\n").uniq.join("\n")
    end
  end

  def self.invalid_email(contact, fields)
    fields.each do |field|
      valid_email = /^[^\s"';@()><\\]*@{1}{1}[^\s"';@()><\\]*.[^\s"';@()><\\]*$/
      if !Util.nil_or_empty?(contact[field])
        return true if !contact[field].match(valid_email)
      end
    end
    return false
  end

  def self.delete_invalid_names(contact)
    ["Given Name", "Family Name"].each do |f|
      Row.delete_if_invalid_name(contact, f)
    end
  end

  def self.delete_if_invalid_name(contact, name_field)
    if !Util.nil_or_empty?(contact[name_field])
      if contact[name_field].match(/.*@.*\..*/)
        contact["E-mail 1 - Value"] = contact[name_field] if Util.nil_or_empty?(contact["E-mail 1 - Value"])
        contact[name_field] = ""
      elsif !contact[name_field].match(/[a-zA-Z]+/)
        contact[name_field] = ""
      end
    end
  end

  def self.move_contact_name(contact)
    if contact["Family Name"] && Util.nil_or_empty?(contact["Given Name"])
      contact["Given Name"] = contact["Family Name"]
      contact["Family Name"] = ""
    end
  end

  def self.make_name(contact)
    if !(contact["Name"]) || Util.nil_or_empty?(contact["Name"])
      if Util.nil_or_empty?(contact["Given Name"]) && Util.nil_or_empty?(contact["Family Name"])
        contact["Name"] = ""
      else
        contact["Name"] = "#{contact["Given Name"]} #{contact["Family Name"]}"
      end
    end
  end

  def self.remove_duplicates(struc_fields, contact)
    hashy = self.get_hash(contact, struc_fields)
    self.set_fields(struc_fields, hashy, contact)
  end

  def self.get_hash(contact, struc_fields)
    field_hash = {}

    struc_fields.each do |field, subfields|
      subfield_type = subfields[0]
      subvalues = self.value_subfields(contact, subfields)
      if Util.field_not_empty?(subvalues)
        Util.add_value_to_hash(field_hash, subvalues,contact[subfield_type])
      end
    end

    Util.join_hash_values(field_hash)
  end

  def self.set_fields(struc_fields, field_hash, contact)
    unique_vals = self.unique_vals(field_hash)
    unique_vals.each {|val| val.unshift(field_hash[val]) }

    local_struc_fields = struc_fields.dup
    local_struc_fields.each do |field, subfields|
      next_val = unique_vals.shift || []
      subfields.each do |subfield|
       contact[subfield] = next_val.shift || ""
      end
      local_struc_fields.delete(field)
    end
  end

  def self.unique_vals(field_hash)
    fields = field_hash.keys
    (0..fields.size-1).each do |index|
      (0..fields.size-1).each do |comp|
        if (fields[comp] - fields[index]).empty? && comp != index
          field_hash.delete(fields[comp])
        end
      end
    end
    field_hash.keys
  end

  def self.value_subfields(contact, subfields)
    subfields[1..-1].map {|val| contact[val]}
  end

  def self.enough_contact_info(contact)
    !Util.nil_or_empty?(contact["E-mail 1 - Value"]) || (!Util.nil_or_empty?(contact["Name"]) || !Util.nil_or_empty?(contact["Phone 1 - Value"]))
  end

end

class CSV::Row

  def has_field?(header)
    ! Util.nil_or_empty?(field(header)) 
  end

end