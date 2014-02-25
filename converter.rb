require './contact_list.rb'

google = ContactList.new({source_file: "source/google.csv"})
# icloud = ContactList.new({source_file: "source/icloud.csv", config_file: "icloud.yaml"})
# cardscan = ContactList.new({source_file: "source/cardscan.csv",
#                         config_file: "cardscan.yaml"})


def format_contact(contact_list)
  contact_list.process_phones
  contact_list.process_fields
  contact_list.delete_blank_columns
  contact_list
end
