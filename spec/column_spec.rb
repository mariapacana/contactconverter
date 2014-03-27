require 'rspec'
require 'yaml'
require 'csv'
require 'set'

require_relative '../column'
require_relative '../constants'

include Constants

describe Column do
  describe "should merge together duplicate info for one contact" do
    let(:myrt) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates_col_single.csv", __FILE__)), headers: true)}
    let(:new_contact) { Hash.new }
    context "in the case of phones" do
      before(:each) {Column.remove_field_dups(STRUC_PHONES, myrt, new_contact) }
      it "should de-duplicate phone values" do
        phones = Set.new ([new_contact["Phone 1 - Value"], new_contact["Phone 2 - Value"]])
        phones.size.should eq(2)
        phones.member?("15138678351").should eq(true)
        phones.member?("16178889929").should eq(true)
      end
      it "should de-duplicate phone types" do
        phone_types = Set.new ([new_contact["Phone 1 - Type"], new_contact["Phone 2 - Type"]])
        phone_types.size.should eq(2)
        phone_types.member?("mobile").should eq(true)
        phone_types.member?("home").should eq(true)
      end
    end
    context "in the case of addresses" do
      before(:each) {Column.remove_field_dups(STRUC_ADDRESSES, myrt, new_contact) }
      it "should consolidate addresses" do
        addresses = Set.new([new_contact["Address 1 - Street"], new_contact["Address 2 - Street"]])
        addresses.size.should eq(2)
        addresses.member?("1124 Golden Bear Avenue").should eq(true)
        addresses.member?("6623 West Haven Avenue").should eq(true)
      end
    end
  end
end