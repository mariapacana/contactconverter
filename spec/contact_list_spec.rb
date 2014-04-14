require 'rspec'
require 'csv'

require_relative '../contact_list'
require_relative '../constants'
require_relative '../row'

include Constants

describe ContactList do

  let (:icloud) {ContactList.new(source_file: File.expand_path("../fixtures/icloud_subset.csv", __FILE__),
                                 config_file: File.expand_path("../../config/icloud.yaml", __FILE__))}
  let (:sageact) {ContactList.new(source_file: File.expand_path("../fixtures/sageact_subset.csv", __FILE__),
                                 config_file: File.expand_path("../../config/sageact.yaml", __FILE__))}
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

  describe "<<" do
    let (:added_headers) {sageact.headers - (icloud.headers & sageact.headers)}
    let (:new_headers) {icloud.headers + added_headers}
    let (:new_icloud) {icloud << sageact}
    it "should merge together the headers" do
      (new_icloud.headers - new_headers).should be_empty
    end
    it "should have the same number of contacts" do
      (new_icloud.contacts.size).should eq(6)
    end
    context "when given invalid args" do
      it "should raise error" do
        expect{icloud << "whimper"}.to raise_error
      end
    end
  end

  describe "#format_list" do
    before(:each) { icloud.format_list }
    it "should sort the address fields" do
      icloud.contacts[0]["Address 1 - Street"].should eq("360 Asteroid Terrace\nBelgrade")
      icloud.contacts[0]["Address 1 - Type"].should eq("Home")
      icloud.contacts[1]["Address 1 - Street"].should eq("69 Sasquatch Lane")
      icloud.contacts[1]["Address 1 - PO Box"].should eq("PO Box 340")
      icloud.contacts[1]["Address 1 - Type"].should eq("Home")
    end
    it "should consolidate emails" do
      icloud.contacts[0]["E-mail 1 - Value"].should eq("moose@goose.com")
      icloud.contacts[0]["E-mail 2 - Value"].should eq("flax@bax.com")
      icloud.contacts[0]["E-mail 3 - Value"].should be_empty
    end
    it "should remove contacts without enough info" do
      icloud.contacts["Name"].should_not include("Widgy")
    end
    it "should have an id column" do
      icloud.contacts["ID"].should_not be_empty
      (icloud.contacts[1]["ID"].to_i - icloud.contacts[0]["ID"].to_i).should eq(1)
    end
  end

  describe "#remove_and_process_duplicate_contacts" do
    context "when stripping email duplicates" do
      before(:each) do 
        dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
      end
      let(:email_dups) {CSV.read(File.open(File.expand_path("../google_E-mail 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
      it "removes email duplicates from list of contacts" do
        dups.contacts["E-mail 1 - Value"].should include("sally@whelk.com")
        dups.contacts["E-mail 1 - Value"].should include("downy@down.com")
        dups.contacts["E-mail 1 - Value"].should_not include("cal@gopher.com")
      end
      it "saves email duplicates to a file and merges them together" do
        email_dups.size.should eq(3)
        email_dups[0]["Given Name"].should eq("Myrtle")
        email_dups[0]["Family Name"].should eq("Wyckoff\nWackoff")
        email_dups[2]["Name"].should eq("Hal Hal\nHal")
      end
    end
    context "when processing phone duplicates" do
      before(:each) do 
        dups.remove_and_process_duplicate_contacts("Phone 1 - Value")
      end
      let(:phone_dups) {CSV.read(File.open(File.expand_path("../google_Phone 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
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
      let(:email_dups) {CSV.read(File.open(File.expand_path("../google_E-mail 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
      it "should merge together emails" do
        email_dups.size.should eq(1)
        sageact_dups.contacts.size.should eq(2)
      end
    end
  end
  describe "#remove_duplicate_contacts" do
    it "should save contacts duplicated by email into a hash and return it" do
      email_hash = dups.remove_duplicate_contacts("E-mail 1 - Value")
      email_hash.keys.size.should eq(3)
      phone_hash = dups.remove_duplicate_contacts("Phone 1 - Value")
      phone_hash.keys.size.should eq(1)
      dups.contacts["E-mail 1 - Value"].should_not include("myrtle@wood.com")
    end
  end
end