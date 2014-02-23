require 'contact'

google = Contact.new({source_file: "source/google.csv"})
icloud = Contact.new({source_file: "source/icloud.csv",
                      config_file: "icloud.yaml"})
cardscan = Contact.new({source_file: "source/cardscan.csv",
                        config_file: "cardscan.yaml"})
