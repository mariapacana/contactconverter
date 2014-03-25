require 'yaml'

module Constants

  G_HEADERS = YAML.load(File.open('google.yaml'))
  FIELDS = YAML.load(File.open('google_by_category.yaml'))
  STRUC_FIELDS = YAML.load(File.open('structured.yaml'))
  COMPARISON = YAML.load(File.open('comparison.yaml'))

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

  UNIQUE_HEADERS =  G_HEADERS - FIELDS["phones"]["type"] - FIELDS["phones"]["value"] - FIELDS["websites"]["type"] - FIELDS["websites"]["value"] - FIELDS["addresses"]["type"]- FIELDS["addresses"]["formatted"]- FIELDS["addresses"]["type"]- FIELDS["addresses"]["street"]- FIELDS["addresses"]["city"]- FIELDS["addresses"]["pobox"]- FIELDS["addresses"]["region"]- FIELDS["addresses"]["postal_code"]- FIELDS["addresses"]["country"]- FIELDS["addresses"]["extended"]- FIELDS["emails"]["type"] - FIELDS["emails"]["value"] - FIELDS["names"]

end