module Row

  def self.move_contact_name(contact)
    if contact["Family Name"] && (contact["Given Name"].nil? || contact["Given Name"] == "")
      contact["Given Name"] = contact["Family Name"]
      contact["Family Name"] = ""
    end
  end

  def self.make_name(contact)
    if !(contact["Name"]) || (contact["Name"] == "") || (contact["Name"].nil?)
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
end