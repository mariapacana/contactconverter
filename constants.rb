require 'yaml'

module Constants

  G_HEADERS = YAML.load(File.open('google.yaml'))
  FIELDS = YAML.load(File.open('google_by_category.yaml'))
  EMAILS = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
  WEBSITES = Hash[FIELDS["websites"]["value"].zip(FIELDS["websites"]["type"])]
  PHONES = Hash[FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"])]
  NAMES = FIELDS["names"]
  ADDRESSES = FIELDS["addresses"]
  FIRST_EMAIL = FIELDS["emails"]["value"][0]

  STRUC_FIELDS = YAML.load(File.open('structured.yaml'))
  STRUC_ADDRESSES = STRUC_FIELDS["addresses"]

end