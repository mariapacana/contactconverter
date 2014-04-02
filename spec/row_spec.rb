require 'rspec'
require 'yaml'
require 'csv'

require_relative '../row'
require_relative '../constants'

include Constants

describe Row do

  let (:phone_headers) {FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"]).flatten}
  let (:contact_1) {CSV::Row.new(phone_headers, ["(312) 838-3923", nil, "(312) 838-3923", nil, "(312) 838-3443", nil,"(312) 234-3237", nil,"(312) 658-3923", nil,])}
  let (:bad_email) {CSV::Row.new(FIELDS["emails"]["value"], ["'>,Mugwump Gundrun' <Mugwump.Gundrun@'@smtp5.homesteadmail.com", nil, nil, nil])}
  let (:good_email) {CSV::Row.new(FIELDS["emails"]["value"], ["hey@there.com", "so@what.com", nil, nil])}

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

  describe "fixes phones and emails" do
    it "should put phones in format +19995558888" do
      Row.standardize_phones(contact_1, ["Phone 2 - Value", "Phone 3 - Value"])
      contact_1["Phone 2 - Value"].should eq("+13128383923")
      contact_1["Phone 3 - Value"].should eq("+13128383443")
    end
    it "can flag emails that aren't blah@blah.com" do
      Row.invalid_email(bad_email, FIELDS["emails"]["value"]).should eq(true)
      Row.invalid_email(good_email, FIELDS["emails"]["value"]).should eq(false)
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

  describe "#standardize_notes" do
    let(:notes_unformatted) {CSV.read(File.open(File.expand_path("../fixtures/notes_strip.csv", __FILE__)), headers: true)}
    let(:larry) {notes_unformatted[0]}
    let(:phil) {notes_unformatted[1]}
    let(:mudgeon) {notes_unformatted[2]}
    it "removes all the externally added fields from the notes" do
      notes_unformatted.each {|c| Row.standardize_notes(c)}
      larry["Notes"].should eq("# 7306 LEASING")
      phil["Notes"].should eq("# 464")
      mudgeon["Notes"].should eq("# 543\n# 54\nLooking for an 8' slider 12/12/2048")
    end 
  end

  describe "removes duplicate email, phone, website info from rows" do
    let(:duplicates) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates.csv", __FILE__)), headers: true)}
    let(:email_dups) {duplicates[0]}
    let(:phone_dups) {duplicates[1]}
    let(:website_dups) {duplicates[2]}
    let(:email_dups_no_types) {duplicates[3]}
    let(:address_dups) {duplicates[4]}
    it "removes duplicate emails" do
      Row.remove_duplicates(STRUC_EMAILS, email_dups)
      Row.remove_duplicates(STRUC_EMAILS, email_dups_no_types)
      email_dups["E-mail 1 - Value"].should eq("myrtle@wood.com")
      email_dups["E-mail 1 - Type"].should eq("home\nbusiness")
      email_dups["E-mail 2 - Value"].should eq("pacificsunrise@coast.com")
      email_dups_no_types["E-mail 1 - Value"].should eq("support@suppot.net")
    end
    it "removes duplicate phones" do
      Row.standardize_phones(phone_dups, FIELDS["phones"]["value"])
      Row.remove_duplicates(STRUC_PHONES, phone_dups)
      phone_dups["Phone 1 - Value"].should eq("+13125835832")
      phone_dups["Phone 1 - Type"].should eq("mobile\nhome")
      phone_dups["Phone 2 - Value"].should eq("+18439992842")
    end
    it "removes duplicate addresses" do
      Row.remove_duplicates(STRUC_ADDRESSES, address_dups)
      address_dups["Address 1 - Street"].should eq("1180 Stony Marsh Blvd.")
      address_dups["Address 2 - Country"].should be_empty
      address_dups["Address 2 - Postal Code"].should be_empty
    end

  end

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