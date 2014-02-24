module Phone

  def self.get_phone_types(person)
    person['Phone 2 - Type'] = 'mobile' if person.has_field?('Phone 2 - Value')
    person['Phone 3 - Type'] = 'home' if person.has_field?('Phone 3 - Value')
    person['Phone 4 - Type'] = 'pager' if person.has_field?('Phone 4 - Value')

    if person['Phone 1 - Value'] == person['Phone 2 - Value']
      person['Phone 1 - Type'] = 'mobile'
    elsif person['Phone 1 - Value'] == person['Phone 3 - Value']
      person['Phone 1 - Type'] = 'home'
    elsif person['Phone 1 - Value'] == person['Phone 4 - Value']
      person['Phone 1 - Type'] = 'pager'
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

end