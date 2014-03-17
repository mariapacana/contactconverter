module Util

  def self.nil_or_empty?(value)
    value.nil? || value == "" || value.empty?
  end

end