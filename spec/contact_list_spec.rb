require 'rspec'

require_relative '../contact_list'
require_relative '../constants'
require_relative '../row'

include Constants

describe ContactList do

  let (:icloud) {ContactList.new(source_file: File.expand_path("../fixtures/icloud_fixture.csv", __FILE__),
                                 config_file: File.expand_path("../../icloud.yaml", __FILE__))}
  let (:icloud_dups) {ContactList.new(source_file: File.expand_path("../fixtures/contact_duplicates_col.csv", __FILE__))}

  # let(:email_hash){icloud_dups.remove_duplicate_contacts("E-mail 1 - Value")}

  describe "#initialize" do
    it "should put everything in a Google header format" do
      (G_HEADERS - icloud.headers).should be_empty
    end
  end

  describe "#format_list" do
    it "should remove contacts without info" do
      icloud.format_list
      icloud.contacts["IC - id"].should_not include("pas-id-53095B97000023A3")
      icloud.contacts["IC - id"].should include("pas-id-53095B97000023B2")
    end
  end

  describe "#remove_and_process_duplicate_contacts" do
    it "should merge together contact info for contacts in a field hash" do
     table = icloud_dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
     # Write something useful here
    end
    it "should raise error" do
      expect {icloud_dups.remove_and_process_duplicate_contacts("booga")}.to raise_error
    end
  end

  describe "#remove_duplicate_contacts" do
    it "should save contacts duplicated by email into a hash and return it" do
      email_hash = icloud_dups.remove_duplicate_contacts("E-mail 1 - Value")
      email_hash.keys.size.should eq(2)
      phone_hash = icloud_dups.remove_duplicate_contacts("Phone 1 - Value")
      phone_hash.keys.size.should eq(1)
      icloud_dups.contacts["E-mail 1 - Value"].should_not include("myrtle@wood.com")
    end
    xit "should save the pared-down contacts in a file" do
    end
  end
end