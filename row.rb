require File.expand_path('../util.rb', __FILE__)
require 'pry'

module Row

  include Util

  def self.get_phone_types(person)
    person['Phone 2 - Type'] = 'mobile' if person.has_field?('Phone 2 - Value')
    person['Phone 3 - Type'] = 'home' if person.has_field?('Phone 3 - Value')
    person['Phone 4 - Type'] = 'pager' if person.has_field?('Phone 4 - Value')
    person['Phone 5 - Type'] = 'fax' if person.has_field?('Phone 5 - Value')

    if !Util.nil_or_empty?(person['Phone 1 - Value'])
      if person['Phone 1 - Value'] == person['Phone 2 - Value']
        person['Phone 1 - Type'] = 'mobile'
      elsif person['Phone 1 - Value'] == person['Phone 3 - Value']
        person['Phone 1 - Type'] = 'home'
      elsif person['Phone 1 - Value'] == person['Phone 4 - Value']
        person['Phone 1 - Type'] = 'pager'
      end
    end
  end

  def self.standardize_phones(person, fields)
    fields.each do |field|
      phone = person[field]
      if !Util.nil_or_empty?(phone)
        phone.gsub!(/(\D)/,"")
        if phone.length == 11
          phone.insert(0, '+')
        elsif phone.length == 10
          phone.insert(0, '+1') 
        end
        person[field] = phone
      end
    end
  end

  def self.invalid_email(person, fields)
    fields.each do |field|
      valid_email = /^[^\s"';@()><\\]*@{1}{1}[^\s"';@()><\\]*.[^\s"';@()><\\]*$/
      if !Util.nil_or_empty?(person[field])
        return true if !person[field].match(valid_email)
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

      if self.field_not_empty?(subvalues)
        if !field_hash.has_key?(subvalues)
          field_hash[subvalues] = [contact[subfield_type]]
        else
          field_hash[subvalues] << contact[subfield_type]
        end
      end
    end

    Util.join_hash_values(field_hash)
  end

  def self.set_fields(struc_fields, field_hash, contact)
    unique_vals = field_hash.keys.uniq
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

  def self.value_subfields(contact, subfields)
    subfields[1..-1].map {|val| contact[val]}
  end

  def self.field_not_empty?(subvalues)
    subvalues.select {|value| !Util.nil_or_empty?(value)}.size >= 1
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