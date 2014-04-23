require_relative 'constants'
require_relative 'util'
require 'pry'

module ContactCSV

  include Util
  include Constants

  def self.similarity_tests(field, comparison_field, contact)
    if field == "Name"
      return self.contact_has_both_names?(field, contact) || self.test_emails_phones(contact)
    else
      return self.backup_fields_also_similar?(COMPARISON[field], contact)
    end
  end

  def self.test_emails_phones(contact)
    self.test_vals(contact, EMAIL_VALS) || self.test_vals(contact, PHONE_VALS)
  end

  def self.test_vals(contact, vals)
    !contact.map{|c| vals.map {|v| c[v]}}.reduce(:&).nil?
  end

  def self.contact_has_both_names?(field, contact)
    !(Util.nil_or_empty?(contact["Given Name"].uniq[0])) && !(Util.nil_or_empty?(contact["Family Name"].uniq[0]))
  end

  def self.backup_fields_also_similar?(fields, contact)
    fields.each {|f|return true if self.backup_field_similar?(f, contact)}
    return true if self.longest_name_includes_names?(contact)
    return false
  end

  def self.backup_field_similar?(field, contact)
    vals = Util.flatten_and_get_non_nil_uniques(contact[field])
    vals = vals.map { |val| val.nil? ? nil : val[0..2].downcase}.uniq
    self.one_val_or_fewer(vals)
  end

  def self.longest_name_includes_names?(contact)
    sorted_names = contact["Name"].map {|name| name.nil? ? "" : name.split("\n")}.flatten.sort_by {|name| name.length}
    longest_name = sorted_names.pop
    sorted_names.each {|name| return false if !longest_name.include?(name)}
    return true
  end

  def self.one_val_or_fewer(vals)
    vals.select {|val| !Util.nil_or_empty?(val) }.size < 2
  end
end