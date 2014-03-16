require './contact_list.rb'

google = ContactList.new({source_file: "source/google.csv"})
icloud = ContactList.new({source_file: "source/icloud.csv", config_file: "icloud.yaml"})
cardscan = ContactList.new({source_file: "source/cardscan.csv", config_file: "cardscan.yaml"})
