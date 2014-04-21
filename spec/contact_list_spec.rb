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
  let (:title_dups) {ContactList.new(source_file: File.expand_path("../fixtures/overcorrecting.csv", __FILE__))}
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
      (new_icloud.size).should eq(7)
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
      icloud.contacts.size.should eq(3)
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
      icloud.contacts[-1]["ID"].should eq("3")
    end
  end

  describe "#remove_and_process_duplicate_contacts" do
    context "when stripping email duplicates" do
      before(:each) do 
        dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
      end
      it "merges contacts with duplicated emails together" do
        dups.size.should eq(9)
        dups.contacts["Given Name"].should include("Myrtle")
        dups.contacts["Family Name"].should include("Wyckoff\nWackoff")
        dups.contacts["ID"].should include("1\n2\n13")
        dups.contacts["ID"].should include("10\n11\n12")
        dups.contacts["Name"].should include("Hal Hal\nHal")
      end
    end
    context "when processing phone duplicates" do
      before(:each) do 
        dups.add_id_column
        dups.remove_and_process_duplicate_contacts("Phone 1 - Value")
      end
      it "merges contacts with duplicated phone numbers together" do
        dups.size.should eq(15)
        dups.contacts["Name"].should include("Edgar Thistledown\nEdgar\nThistledown")
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
      it "should merge together emails" do
        sageact_dups.contacts.size.should eq(3)
      end
    end
    context "when processing dups that are prefixed by a title" do
      it "recognizes that they are the same" do
        title_dups.remove_and_process_duplicate_contacts("E-mail 1 - Value")
        title_dups.contacts["Name"].should include("President Higgledy Piggledy\nHiggledy Piggledy")
      end
    end
  end
end