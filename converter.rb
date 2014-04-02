require './contact_list.rb'

def combine_and_convert
  puts "creating contact lists..."
  google = ContactList.new({source_file: "archive/source/google.csv"})
  icloud = ContactList.new({source_file: "archive/source/icloud.csv", config_file: "config/icloud.yaml"})
  cardscan = ContactList.new({source_file: "archive/source/cardscan.csv", config_file: "config/cardscan.yaml"})
  sageact = ContactList.new({source_file: "archive/source/sageact2.csv", config_file: "config/sageact.yaml"})

  all = [google, icloud, cardscan, sageact]

  puts "formatting contact lists..."
  all.map {|list| list.format_list}

  puts "merging all lists..."
  all[1..-1].each {|list| google << list}

  puts "saving to file..."
  google.save_to_file("all_contacts_before.csv")

  puts "deduping emails..."
  google.remove_and_process_duplicate_contacts("E-mail 1 - Value")

  puts "deduping phones..."
  google.remove_and_process_duplicate_contacts("Phone 1 - Value")

  puts "deduping names..."
  google.remove_and_process_duplicate_contacts("Name")

  puts "saving final version..."
  google.save_to_file("all_contacts_after.csv")
end

combine_and_convert