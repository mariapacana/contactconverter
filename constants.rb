require 'yaml'

module Constants

  G_HEADERS = YAML.load(File.open(File.expand_path('../config/google.yaml', __FILE__)))
  FIELDS = YAML.load(File.open(File.expand_path('../config/google_by_category.yaml', __FILE__)))
  STRUC_FIELDS = YAML.load(File.open(File.expand_path('../config/structured.yaml', __FILE__)))
  COMPARISON = YAML.load(File.open(File.expand_path('../config/comparison.yaml', __FILE__)))
  SHORTNAMES = YAML.load(File.open(File.expand_path('../config/shortnames.yaml', __FILE__)))

  EMAILS = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
  WEBSITES = Hash[FIELDS["websites"]["value"].zip(FIELDS["websites"]["type"])]
  PHONES = Hash[FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"])]
  NAMES = FIELDS["names"]
  ADDRESSES = FIELDS["addresses"]
  STRUC_ADDRESSES = STRUC_FIELDS["addresses"]
  STRUC_PHONES = STRUC_FIELDS["phones"]
  STRUC_WEBSITES = STRUC_FIELDS["websites"]
  STRUC_EMAILS = STRUC_FIELDS["emails"]

  FIRST_EMAIL = FIELDS["emails"]["value"][0]

  UNIQUE_HEADERS =  G_HEADERS - FIELDS["phones"]["type"] - FIELDS["phones"]["value"] - FIELDS["websites"]["type"] - FIELDS["websites"]["value"] - FIELDS["addresses"]["type"]- FIELDS["addresses"]["formatted"]- FIELDS["addresses"]["type"]- FIELDS["addresses"]["street"]- FIELDS["addresses"]["city"]- FIELDS["addresses"]["pobox"]- FIELDS["addresses"]["region"]- FIELDS["addresses"]["postal_code"]- FIELDS["addresses"]["country"]- FIELDS["addresses"]["extended"]- FIELDS["emails"]["type"] - FIELDS["emails"]["value"]

  ALL_CARDSCAN_FIELDS = YAML.load(File.open(File.expand_path('../config/cardscan.yaml', __FILE__))).keys + YAML.load(File.open(File.expand_path('../config/mystery.yaml', __FILE__))).keys

  # All structured addresses
  SA_STRUC = YAML.load(File.open(File.expand_path('../config/sageact_struc_addresses.yaml', __FILE__)))
  SA_STRUC_ADDRESSES = SA_STRUC["addresses"]
  SA_STRUC_EXTENSIONS = SA_STRUC["phones"]["extensions"]
  SA_STRUC_DELETE = SA_STRUC_ADDRESSES.values.flatten + SA_STRUC_EXTENSIONS.keys + ['SA - Alternate Phone']
  CS_STRUC_ADDRESSES = YAML.load(File.open(File.expand_path('../config/cardscan_struc_addresses.yaml', __FILE__)))
  CS_STRUC_DELETE = CS_STRUC_ADDRESSES.values.flatten
  IC_STRUC_ADDRESSES = YAML.load(File.open(File.expand_path('../config/icloud_struc_addresses.yaml', __FILE__)))
  IC_STRUC_DELETE = IC_STRUC_ADDRESSES.values.flatten

end