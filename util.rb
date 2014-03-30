module Util

  def self.nil_or_empty?(value)
    value.nil? || value == "" || value.empty?
  end

  def self.set_value_if_nil(my_hash, my_key, new_value)
    my_hash[my_key] = new_value if self.nil_or_empty?(my_hash[my_key])
  end

  def self.join_hash_values(my_hash)
    my_hash.each do |key, value|
      if value.uniq.size > 1
        my_hash[key] = value.join("\n")
      elsif value.uniq.size == 1
        my_hash[key] = value.uniq[0]
      else
        my_hash[key] = ""
      end
    end
  end

  def self.field_not_empty?(field)
    field.select {|value| !self.nil_or_empty?(value)}.size >= 1
  end

  def self.add_value_to_hash(my_hash, hash_key, hash_value)
    if my_hash.has_key?(hash_key)
      my_hash[hash_key] << hash_value
    else
      my_hash[hash_key] = [hash_value]
    end
  end

  def self.convert_contact_arry_to_csv(contacts_arry)
    rows = []
    contacts_arry.each do |contact|
      field_arry = []
      G_HEADERS.each {|header| field_arry << contact[header] || nil }
      rows << CSV::Row.new(G_HEADERS, field_arry)
    end
    table = CSV::Table.new(rows)
  end

  def self.write_csv_to_file(filename, table)
    CSV.open(filename, "wb") do |csv|
      csv << table.headers
      table.each { |row| csv << row }
    end
  end
end