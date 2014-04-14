require_relative 'util'
require_relative 'constants'

require 'pry'

module Row

  include Util
  include Constants

  def self.strip_fields(contact)
    contact.headers.each {|h| contact[h] = contact[h].strip.gsub(/\\n/, "\n") if !Util.nil_or_empty?(contact[h])}
  end

  def self.remove_colons(struc_fields, contact)
    struc_fields.values.flatten.each do |val|
      contact[val] = contact[val].gsub(":::", "").strip
    end
  end

  def self.get_phone_types(contact)
    contact['Phone 2 - Type'] = 'Mobile' if contact.has_field?('Phone 2 - Value')
    contact['Phone 3 - Type'] = 'Home' if contact.has_field?('Phone 3 - Value')
    contact['Phone 4 - Type'] = 'Pager' if contact.has_field?('Phone 4 - Value')
    contact['Phone 5 - Type'] = 'Fax' if contact.has_field?('Phone 5 - Value')

    if !Util.nil_or_empty?(contact['Phone 1 - Value'])
      if contact['Phone 1 - Value'] == contact['Phone 2 - Value']
        contact['Phone 1 - Type'] = 'Mobile'
      elsif contact['Phone 1 - Value'] == contact['Phone 3 - Value']
        contact['Phone 1 - Type'] = 'Home'
      elsif contact['Phone 1 - Value'] == contact['Phone 4 - Value']
        contact['Phone 1 - Type'] = 'Pager'
      elsif contact['Phone 1 - Value'] == contact['Phone 4 - Value']
        contact['Phone 1 - Type'] = 'Fax'
      else
        contact['Phone 1 - Type'] = 'Main'
      end
    end
  end

  def self.standardize_google(struc_fields, contact)
    new_vals = []
    struc_fields.each do |field, subfields|
      subfield_type = subfields[0]
      subvalues = self.value_subfields(contact, subfields)
      if Util.field_not_empty?(subvalues)
        subvalues.map! {|v| v.split(" ::: ") if !Util.nil_or_empty?(v)}
        until subvalues.select {|ary| !Util.nil_or_empty?(ary)}.empty?
          new_vals << subvalues.map {|v| Util.nil_or_empty?(v) ? "" : v.shift}.unshift(contact[subfield_type])
        end
      end 
    end
    self.set_fields(struc_fields, new_vals.uniq, contact)
    self.remove_colons(struc_fields, contact)
  end

  def self.standardize_phones(contact, fields)
    fields.each do |field|
      phone = contact[field]
      if !Util.nil_or_empty?(phone)
        if p = phone.match(/(?<phone>[\d\-\.\s\(\)]+)(e, ext.t|\sExt\s|\sEXT\s|\sExt.\s|\sext.\s)(?<extension>[\d]+).*/)
          contact[field]= "#{self.fix_phone_number(p[:phone])} Ext. #{p[:extension]}"
        else
          contact[field] = self.fix_phone_number(phone)
        end 
      end
    end
  end

  def self.fix_phone_number(phone)
    phone.gsub!(/(\D)/,"")
    phone.insert(0, '1') if phone.length == 10
    phone
  end

  ## Had to replace \\n with \n.\. If we decide to save the data,
  ## will have to use String#scan.
  def self.standardize_notes(contact)
    cardscan_regexp = /^(#{ALL_CARDSCAN_FIELDS.join("|")}):\s.*$/
    if !Util.nil_or_empty?(contact["Notes"])
      values = contact["Notes"].gsub(cardscan_regexp, "").strip.split("\n")
      contact["Notes"] = Util.join_and_format_uniques(values)
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
    self.assign_vals_to_fields(struc_fields, hashy, contact)
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

  def self.assign_vals_to_fields(struc_fields, field_hash, contact)
    unique_vals = self.unique_vals(field_hash)
    unique_vals.each {|val| val.unshift(field_hash[val]) }
    self.set_fields(struc_fields, unique_vals, contact)
  end

  def self.set_fields(struc_fields, unique_vals, contact)
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