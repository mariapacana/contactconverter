require 'rspec'
require 'csv'

require_relative '../contact_list'
require_relative '../constants'
require_relative '../row'

include Constants

describe ContactList do

  let (:icloud) {ContactList.new(source_file: File.expand_path("../fixtures/icloud_fixture.csv", __FILE__),
                                 config_file: File.expand_path("../../config/icloud.yaml", __FILE__))}
  let (:dups) {ContactList.new(source_file: File.expand_path("../fixtures/contact_duplicates_col.csv", __FILE__))}
  let (:sageact_dups) {ContactList.new(source_file: File.expand_path("../fixtures/sage_duplicates.csv", __FILE__), config_file: File.expand_path("../../config/sageact.yaml", __FILE__))}

  let(:email_hash){dups.remove_duplicate_contacts("E-mail 1 - Value")}

  before(:each) do
    dups.format_list
    sageact_dups.format_list
  end

  describe "#initialize" do
    it "should put everything in a Google header format" do
      (G_HEADERS - icloud.headers).should be_empty
    end
  end

  describe "#format_list" do
    xit "should sort the address fields" do
    end
  end

  describe "#remove_and_process_duplicate_contacts" do
    context "when stripping email duplicates" do

      before(:each) do 
        dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
      end
      let(:email_dups) {CSV.read(File.open(File.expand_path("../_E-mail 1 - Value_duplicates.csv", "__FILE__")), headers: true)}

      it "removes email duplicates from list of contacts" do
        dups.contacts["E-mail 1 - Value"].should include("sally@whelk.com")
        dups.contacts["E-mail 1 - Value"].should include("downy@down.com")
        dups.contacts["E-mail 1 - Value"].should_not include("cal@gopher.com")
      end

      it "saves email duplicates to a file and merges them together" do
        email_dups.size.should eq(2)
        email_dups[0]["Given Name"].should eq("Myrtle")
        email_dups[0]["Family Name"].should eq("Wyckoff\nWackoff")
      end
    end

    context "when processing phone duplicates" do
      before(:each) do 
        dups.remove_and_process_duplicate_contacts("Phone 1 - Value")
      end
      let(:phone_dups) {CSV.read(File.open(File.expand_path("../_Phone 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
      it "removes phone duplicates from list of contacts" do
        dups.contacts["Name"].should_not include("Edgar Thistledown")
      end
      it "saves phone duplicates to a file and merges them together" do
        phone_dups.size.should eq(1)
      end
    end

    context "when given invalid arguments" do
      it "should raise error" do
        expect {dups.remove_and_process_duplicate_contacts("booga")}.to raise_error
      end

    end

    context "in the case of SageAct" do
      before(:each) do
        sageact_dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
      end
      let(:email_dups) {CSV.read(File.open(File.expand_path("../_E-mail 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
      it "should merge together emails" do
        email_dups.size.should eq(1)
        sageact_dups.contacts.size.should eq(2)
      end
    end
  end

  describe "#remove_duplicate_contacts" do
    it "should save contacts duplicated by email into a hash and return it" do
      email_hash = dups.remove_duplicate_contacts("E-mail 1 - Value")
      email_hash.keys.size.should eq(2)
      phone_hash = dups.remove_duplicate_contacts("Phone 1 - Value")
      phone_hash.keys.size.should eq(1)
      dups.contacts["E-mail 1 - Value"].should_not include("myrtle@wood.com")
    end
  end
end