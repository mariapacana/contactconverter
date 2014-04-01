require_relative 'util'
require_relative 'constants'
require 'pry'

module Column
  include Util
  include Constants

  def self.process_duplicate_contacts(field_hash, field)
    contacts_arry = self.merge_duplicated_contacts(field_hash.values)
    table = Util.convert_contact_arry_to_csv(contacts_arry)
    Util.write_csv_to_file("#{@source_type}_#{field}_duplicates.csv", table)
    table
  end

  def self.merge_duplicated_contacts(dup_contacts_array)
    dup_contacts_array.map do |contact_table|
      new_contact = {}
      self.remove_field_dups(STRUC_PHONES, contact_table, new_contact)
      self.remove_field_dups(STRUC_EMAILS, contact_table, new_contact)
      self.remove_field_dups(STRUC_WEBSITES, contact_table, new_contact)
      self.remove_field_dups(STRUC_ADDRESSES, contact_table, new_contact)
      self.remove_field_dups(STRUC_ADDRESSES, contact_table, new_contact)
      self.merge_headers(UNIQUE_HEADERS, contact_table, new_contact)
      new_contact
    end
  end

  def self.merge_headers(headers, contact_table, new_contact)
    headers.each {|h| new_contact[h] = contact_table[h].uniq.join("\n")}
  end

  def self.remove_field_dups(struc_fields, contact_table, new_contact)
    field_hash = self.get_hash(contact_table, struc_fields)
    Row.set_fields(struc_fields, field_hash, new_contact)
  end

  def self.get_hash(contact_table, struc_fields)
    field_hash = {}
    struc_fields.each do |field, subfields|
      subfield_type_vals = subfields.map {|f| contact_table[f]}
      num_val_sets = subfield_type_vals[0].length
      (0..num_val_sets-1).each do |num|
        vals = subfield_type_vals.map {|s| s[num] }[1..-1]
        type = subfield_type_vals[0][num]
        if Util.field_not_empty?(vals)
          Util.add_value_to_hash(field_hash, vals, type)
        end
      end
    end
    Util.join_hash_values(field_hash)
  end
end