require_relative 'util'
require_relative 'constants'
require 'pry'

module Column
  include Util
  include Constants

  def self.process_duplicate_contacts(contacts, field_hash, field, source_type, headers)
    contacts_array = self.merge_duplicated_contacts(field_hash.values, headers)
    ordered_contacts = contacts_array.map {|c| headers.map {|h| c[h]}}
    ordered_contacts.each {|c| contacts << CSV::Row.new(headers, c) }
  end

  def self.merge_duplicated_contacts(dup_contacts_array, headers)
    dup_contacts_array.map do |contact_table|
      new_contact = {}
      self.remove_field_dups(STRUC_PHONES, contact_table, new_contact)
      self.remove_field_dups(STRUC_EMAILS, contact_table, new_contact)
      self.remove_field_dups(STRUC_WEBSITES, contact_table, new_contact)
      self.remove_field_dups(STRUC_ADDRESSES, contact_table, new_contact)
      self.remove_field_dups(STRUC_ADDRESSES, contact_table, new_contact)
      self.merge_unique_fields(headers - NON_UNIQUE_FIELDS, contact_table, new_contact)
      Row.standardize_notes(new_contact)
      new_contact
    end
  end

  def self.remove_field_dups(struc_fields, contact_table, new_contact)
    field_hash = self.get_hash(contact_table, struc_fields)
    Row.assign_vals_to_fields(struc_fields, field_hash, new_contact)
  end

  def self.merge_unique_fields(headers, contact_table, new_contact)
    headers.each do |h|
      new_contact[h] = Util.join_and_format_uniques(contact_table[h])
    end
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