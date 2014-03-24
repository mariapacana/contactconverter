require File.expand_path('../util.rb', __FILE__)
require 'pry'

module ContactCSV
  def self.similarity_tests(field, comparison_field, contact)
    if field == "Name"
      return name_test(field, contact) || vals_substantially_similar(COMPARISON[field], contact)
    elsif field == FIRST_EMAIL || field == "Phone 1 - Value"
      return vals_substantially_similar(COMPARISON[field], contact)
    end
  end

  def self.name_test(field, contact)
    !(Util.nil_or_empty?(contact["Given Name"].uniq[0])) && !(Util.nil_or_empty?(contact["Family Name"].uniq[0]))
  end

  def self.vals_substantially_similar(field, contact)
    vals = contact[field].map do |val|
      val.nil? ? nil : val[0..1]
    end.uniq
    one_val_or_empty(vals) || only_one_val(vals)
  end

  def self.only_one_val(vals)
    vals.select {|val| val != "" && !val.nil? }.size == 1
  end

  def self.one_val_or_empty(vals)
    vals.size == 1
  end

  def self.given_name_same_as_family(contact)
    !(contact["Given Name"] & contact["Family Name"]).empty?
  end
end