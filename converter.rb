require './contact_list.rb'

google = ContactList.new({source_file: "source/google.csv"})
icloud = ContactList.new({source_file: "source/icloud.csv", config_file: "config/icloud.yaml"})
cardscan = ContactList.new({source_file: "source/cardscan.csv", config_file: "config/cardscan.yaml"})
sageact = ContactList.new({source_file: "source/sageact2.csv", config_file: "config/sageact.yaml"})
