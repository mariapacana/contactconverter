require 'rspec'
require 'yaml'

require_relative '../row'

describe Row do

  FIELDS = YAML.load(File.open(File.expand_path("../../google_by_category.yaml", __FILE__)))
  EMAILS = Hash[FIELDS["emails"]["value"].zip(FIELDS["emails"]["type"])]
  WEBSITES = Hash[FIELDS["websites"]["value"].zip(FIELDS["websites"]["type"])]
  PHONES = Hash[FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"])]
  NAMES = FIELDS["names"]
  ADDRESSES = FIELDS["addresses"]
  FIRST_EMAIL = FIELDS["emails"]["value"][0]

  let (:phone_headers) {FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"]).flatten}
  let (:contact_1) {CSV::Row.new(phone_headers, ["(312) 838-3923", nil, "(312) 838-3923", nil, "(312) 838-3443", nil,"(312) 234-3237", nil,"(312) 658-3923", nil,])}

  describe "#get_phone_types" do
    before(:each) do
      Row.get_phone_types(contact_1)
    end
    it "assigns phone types given values" do
      contact_1["Phone 2 - Type"].should eq("mobile")
      contact_1["Phone 3 - Type"].should eq("home")
      contact_1["Phone 4 - Type"].should eq("pager")
      contact_1["Phone 5 - Type"].should eq("fax")
    end
    it "assigns phone 1's phone type based on info from elsewhere" do
      contact_1["Phone 1 - Type"].should eq("mobile")
    end
  end

  describe "#standardize_phones" do
    it "should put phones in format +19995558888" do
      Row.standardize_phones(contact_1, ["Phone 2 - Value", "Phone 3 - Value"])
      contact_1["Phone 2 - Value"].should eq("+13128383923")
      contact_1["Phone 3 - Value"].should eq("+13128383443")
    end
  end

  describe "can straighten out names" do
    let (:invalid_given_name) {CSV::Row.new(["Family Name", "Given Name", "E-mail 1 - Value"], ["Smith", "9", nil])}
    let (:family_name_is_email) {CSV::Row.new(["Family Name", "Given Name", "E-mail 1 - Value"], ["foo@bar.com", nil, nil])}
    let (:no_given_name) {CSV::Row.new(["Family Name", "Given Name"], ["Smith", ""])}
    let (:no_name) {CSV::Row.new(["Name", "Family Name", "Given Name"], ["","Smith", "Josh"])}
    describe "#delete_if_invalid_name" do
      it "removes names that contain numbers" do
        Row.delete_if_invalid_name(invalid_given_name, "Given Name")
        invalid_given_name["Given Name"].should eq("")
      end
      it "removes names that are e-mail addresses, and puts them in email fields" do
        Row.delete_if_invalid_name(family_name_is_email, "Family Name")
        family_name_is_email["Family Name"].should eq("")
        family_name_is_email["E-mail 1 - Value"].should eq("foo@bar.com")
      end
    end
    describe "#move_contact_name" do
      it "changes Given Name to Family Name if there is no Given Name" do
        Row.move_contact_name(no_given_name)
        no_given_name["Given Name"].should eq("Smith")
      end
    end
    describe "#make_name" do
      it "makes Name the Given Name + Family Name" do
        Row.make_name(no_name)
        no_name["Name"].should eq("Josh Smith")
      end
    end
  end

  # describe "removes duplicate info from rows" do
  #   let(:duplicates) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates.csv", __FILE__)), headers: true)}
  #   let(:email_dups) {duplicates[0]}
  #   let(:phone_dups) {duplicates[1]}
  #   let(:website_dups) {duplicates[2]}
  #   it "removes duplicate emails" do
  #     Row.remove_duplicates(EMAILS, email_dups)
  #     email_dups["E-mail 1 - Value"].should eq("myrtle@wood.com")
  #     email_dups["E-mail 1 - Type"].should eq("business\nhome")
  #     email_dups["E-mail 2 - Value"].should eq("pacificsunrise@coast.com")
  #   end
  #   it "removes duplicate phones" do
  #     Row.standardize_phones(phone_dups, FIELDS["phones"]["value"])
  #     Row.remove_duplicates(PHONES, phone_dups)
  #     phone_dups["Phone 1 - Value"].should eq("+13125835832")
  #     phone_dups["Phone 1 - Type"].should eq("mobile\nhome")
  #     phone_dups["Phone 2 - Value"].should eq("+18439992842")
  #     puts phone_dups
  #   end
  # end


  describe "knows when contacts have enough information" do
    let(:has_info) {CSV.read(File.open(File.expand_path("../fixtures/contacts_enough_info.csv", __FILE__)), headers: true)}
    let(:not_enough_info) {has_info[0]}
    let(:enough_info_phone) {has_info[1]}
    let(:enough_info_email) {has_info[2]}
    it "flags contacts without enough info" do
      Row.enough_contact_info(not_enough_info).should eq(false)
    end
    it "lets contacts go that do have enough info" do
      Row.enough_contact_info(enough_info_phone).should eq(true)
      Row.enough_contact_info(enough_info_email).should eq(true)
    end
  end
end