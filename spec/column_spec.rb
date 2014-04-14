require 'rspec'
require 'yaml'
require 'csv'
require 'set'

require_relative '../column'
require_relative '../constants'


# Note: process_duplicate_contacts and merge_duplicate_contacts are not
# explicitly tested here. They are tested indirectly by testing 
# remove_and_process_duplicate_contacts in contact_list. Instead we test
# remove_field_dups and merge_unique_fields.

include Constants

describe Column do
  describe "#remove_field_dups" do
    let(:myrt) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates_col_single.csv", __FILE__)), headers: true)}
    let(:new_contact) { Hash.new }

    context "when deduping type/value fields" do
      before(:each) {Column.remove_field_dups(STRUC_PHONES, myrt, new_contact) }
      before(:each) {Column.remove_field_dups(STRUC_ADDRESSES, myrt, new_contact) }
      it "should put each phone value in its own field" do
        phones = Set.new ([new_contact["Phone 1 - Value"], new_contact["Phone 2 - Value"]])
        phones.size.should eq(2)
        phones.member?("15138678351").should eq(true)
        phones.member?("16178889929").should eq(true)
      end
      it "should put each phone type in its own field" do
        phone_types = Set.new ([new_contact["Phone 1 - Type"], new_contact["Phone 2 - Type"]])
        phone_types.size.should eq(2)
        phone_types.member?("Mobile").should eq(true)
        phone_types.member?("Home").should eq(true)
      end
      it "should put each address in its own field" do
        addresses = Set.new([new_contact["Address 1 - Street"], new_contact["Address 2 - Street"]])
        addresses.size.should eq(2)
        addresses.member?("1124 Golden Bear Avenue").should eq(true)
        addresses.member?("6623 West Haven Avenue").should eq(true)
      end
    end
  end
  describe "#merge_unique_fields" do
    let(:myrt) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates_col_single.csv", __FILE__)), headers: true)}
    let(:new_contact) { Hash.new }
    it "should merge together unique fields" do
      Column.merge_unique_fields(myrt.headers - NON_UNIQUE_FIELDS, myrt, new_contact)
      new_contact["Name"].should eq("Myrtle Wackoff\nMyrtle")
    end
  end
end