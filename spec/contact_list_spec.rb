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
    it "should put ID first" do
      icloud.headers[0] == "ID"
    end
    it "should put Notes last" do
      icloud.headers[-1] == "Notes"
    end
    it "should delete all headers that are empty" do
      icloud.headers.should_not include("IC - caluri")
      icloud.headers.should_not include("IC - Birth Year")
      icloud.headers.should include("IC - wants_html")
    end
  end

  describe "<<" do
    before(:each) do
      shared_headers = icloud.headers & sageact.headers
      @new_headers = icloud.headers + (sageact.headers - shared_headers)
    end
    let (:new_icloud) {icloud << sageact}
    it "should merge together the headers" do
      new_icloud.headers.sort.should eq(@new_headers.sort)
    end
    it "should have ID as the first header and Notes as the last" do
      new_icloud.headers[0] == "ID"
      new_icloud.headers[-1] == "Notes"
    end
    it "should have the same number of contacts" do
      (new_icloud.size).should eq(6)
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
    it "should delete headers" do
      icloud.headers.should_not include("IC - Business Address2")
      icloud.headers.should_not include("IC - Home Address2")
    end
  end

  describe "#add_id_column" do
    it "should add ids to columns without any" do
      icloud.add_id_column
      icloud.contacts[0]["ID"].should eq("1")
      icloud.contacts[-1]["ID"].should eq("2")
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
        dups.add_id_column
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
        sageact_dups.add_id_column
        sageact_dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
      end
      let(:email_dups) {CSV.read(File.open(File.expand_path("../google_E-mail 1 - Value_duplicates.csv", "__FILE__")), headers: true)}
      it "should merge together emails" do
        email_dups.size.should eq(1)
        sageact_dups.contacts.size.should eq(2)
      end
    end
  end
end