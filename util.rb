module Util

  def self.nil_or_empty?(value)
    value.nil? || value == "" || value.empty?
  end

  def self.join_hash_values(my_hash)
    my_hash.each {|k,v| my_hash[k] = v.size > 1 ? v.join("\n") : v[0] }
  end

end