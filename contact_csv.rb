require_relative 'constants'
require_relative 'util'
require 'pry'

module ContactCSV

  include Util
  include Constants

  def self.similarity_tests(field, comparison_field, contact)
    if field == "Name"
      return self.contact_has_both_names?(field, contact) || backup_field_also_similar?(COMPARISON[field], contact)
    else
      return backup_field_also_similar?(COMPARISON[field], contact)
    end
  end

  def self.contact_has_both_names?(field, contact)
    !(Util.nil_or_empty?(contact["Given Name"].uniq[0])) && !(Util.nil_or_empty?(contact["Family Name"].uniq[0]))
  end

  def self.backup_field_also_similar?(field, contact)
    vals = contact[field].map do |val|
      val.nil? ? nil : val[0..1]
    end.uniq
    one_val_or_empty(vals) || only_one_val(vals)
  end

  def self.only_one_val(vals)
    vals.select {|val| !Util.nil_or_empty?(val) }.size == 1
  end

  def self.one_val_or_empty(vals)
    vals.size == 1
  end
end