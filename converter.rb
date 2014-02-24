require 'contact'

google = ContactList.new({source_file: "source/google.csv"})
icloud = ContactList.new({source_file: "source/icloud.csv", config_file: "icloud.yaml"})
cardscan = ContactList.new({source_file: "source/cardscan.csv",
                        config_file: "cardscan.yaml"})


icloud.delete_blank_columns
icloud.process_phones
icloud.process_fields
icloud.delete_blank_columns
icloud.save_to_file("formatted_icloud.csv")