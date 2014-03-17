require File.expand_path('../util.rb', __FILE__)

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
      if phone
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

  def self.delete_invalid_names(contact)
    ["Given Name", "Family Name"].each do |f|
      Row.delete_if_invalid_name(contact, f)
    end
  end

  def self.delete_if_invalid_name(contact, name_field)
    if !Util.nil_or_empty?(contact[name_field])
      if contact[name_field].match(/\d/)
        contact[name_field] = ""
      elsif contact[name_field].match(/.*@.*\..*/)
        contact["E-mail 1 - Value"] = contact[name_field] if Util.nil_or_empty?(contact["E-mail 1 - Value"])
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
      contact["Name"] = "#{contact["Given Name"]} #{contact["Family Name"]}"
    end
  end

  def self.remove_duplicates(val_type_hash, contact)
    contact_val_types = Row.aggregate_contact_field(val_type_hash, contact)
    unique_values = Row.unique_values(contact_val_types)
    Row.assign_values(contact, val_type_hash, contact_val_types, unique_values)
  end

  # Make a hash containing all data for a particular contact & field.
  def self.aggregate_contact_field(val_type_hash, contact)
    contact_val_types = {}
    val_type_hash.each do |field_val, field_type|
      contact_val_types[contact[field_val]] = contact[field_type]
    end
    contact_val_types
  end

  # Boils it down to unique values
  def self.unique_values(contact_val_types)
    contact_val_types.keys.uniq.select do |field_val| 
      field_val != nil && field_val != ""
    end
  end

  def self.assign_values(contact, val_type_hash, contact_val_types, unique_values)
    val_type_hash.each do |field_val, field_type|
      if !(unique_values.empty?)
        contact_val = unique_values.shift
        contact[field_val] = contact_val
        contact[field_type] = contact_val_types[contact_val]
      else
        contact[field_val] = nil
        contact[field_type] = nil
      end
    end
  end

  def self.enough_contact_info(contact)
    !Util.nil_or_empty?(contact["Name"]) && (!Util.nil_or_empty?(contact["E-mail 1 - Value"]) || !Util.nil_or_empty?(contact["Phone 1 - Value"]))
  end

end