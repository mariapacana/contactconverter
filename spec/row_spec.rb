require 'rspec'
require 'yaml'
require 'csv'

require_relative '../row'
require_relative '../constants'

include Constants

describe Row do

  let (:phone_headers) {FIELDS["phones"]["value"].zip(FIELDS["phones"]["type"]).flatten}
  let (:phone_1) {CSV::Row.new(phone_headers, ["(312) 838-3923", nil, "(312) 838-3923", nil, "(312) 838-3443", nil,"(312) 234-3237", nil,"(312) 658-3923", nil,])}
  let (:phone_2) {CSV::Row.new(phone_headers, ["999-999-9999 ext. 9999", nil, "9-999-999-999e, ext.t9999", nil, "99-999-9999 Ext. 999,", nil,"(999) 999-9999 EXT 999", nil,"999-999-9999 Ext 9", nil,])}
  let (:bad_email) {CSV::Row.new(FIELDS["emails"]["value"], ["'>,Mugwump Gundrun' <Mugwump.Gundrun@'@smtp5.Homesteadmail.com", nil, nil, nil])}
  let (:good_email) {CSV::Row.new(FIELDS["emails"]["value"], ["hey@there.com", "so@what.com", nil, nil])}

  describe "#get_phone_types" do
    before(:each) do
      Row.get_phone_types(phone_1)
    end
    it "assigns phone types given values" do
      phone_1["Phone 2 - Type"].should eq("Mobile")
      phone_1["Phone 3 - Type"].should eq("Home")
      phone_1["Phone 4 - Type"].should eq("Pager")
      phone_1["Phone 5 - Type"].should eq("Fax")
    end
    it "assigns phone 1's phone type based on info from elsewhere" do
      phone_1["Phone 1 - Type"].should eq("Mobile")
    end
  end

  describe "fixes phones and emails" do
    it "should put phones in format +19995558888" do
      Row.standardize_phones(phone_1, ["Phone 2 - Value", "Phone 3 - Value"])
      phone_1["Phone 2 - Value"].should eq("'13128383923")
      phone_1["Phone 3 - Value"].should eq("'13128383443")
    end
    it "should deal with extensions reasonably" do
      Row.standardize_phones(phone_2, ["Phone 1 - Value", "Phone 2 - Value", "Phone 3 - Value", "Phone 4 - Value", "Phone 5 - Value"])
      phone_2["Phone 1 - Value"].should eq("'19999999999 Ext. 9999")
      phone_2["Phone 2 - Value"].should eq("'19999999999 Ext. 9999")
      phone_2["Phone 3 - Value"].should eq("'999999999 Ext. 999")
      phone_2["Phone 4 - Value"].should eq("'19999999999 Ext. 999")
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

  describe "#strip_fields" do
    let (:padded_fields) {CSV::Row.new(["Family Name", "Given Name", "E-mail 1 - Value"], ["  Loy ", "Myrna      ", "  whiffle"])}
    it "removes padding from fields" do
      Row.strip_fields(padded_fields)
      padded_fields["Family Name"].should eq("Loy")
      padded_fields["Given Name"].should eq("Myrna")
    end
  end

  describe "#standardize_google" do
    let(:duplicates) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates.csv", __FILE__)), headers: true)}
    let(:google_phone_dups) {duplicates[7]}
    let(:google_colons) {duplicates[8]}
    let(:google_longnums) {duplicates[9]}
    let(:google_emails) {duplicates[10]}
    it "collapses google phone dups" do
      Row.standardize_google(STRUC_PHONES, google_phone_dups)
      Row.standardize_google(STRUC_ADDRESSES, google_colons)
      google_phone_dups["Phone 1 - Value"].should eq("545-356-3222")
      google_phone_dups["Phone 1 - Type"].should eq("Mobile")
      google_phone_dups["Phone 2 - Value"].should eq("545-135-2352")
      google_phone_dups["Phone 2 - Type"].should eq("Mobile")
      google_phone_dups["Phone 3 - Value"].should eq("535-632-4313")
      google_phone_dups["Phone 3 - Type"].should eq("Home")
      google_phone_dups["Phone 4 - Value"].should eq("678-124-2342")
      google_phone_dups["Phone 4 - Type"].should eq("Home")
      google_phone_dups["Phone 5 - Value"].should eq("2-345-345-5243")
      google_phone_dups["Phone 5 - Type"].should eq("Home")
      google_colons["Address 1 - City"].should eq("Grand Rapids")
      google_colons["Address 1 - Region"].should eq("MI")
    end
    it "can deal with very long numbers" do
      Row.standardize_google(STRUC_PHONES, google_longnums)
      Row.standardize_phones(google_longnums, FIELDS["phones"]["value"])
      google_longnums["Phone 4 - Value"].should eq("'86769226913022269130322612663")
    end
    it "can split apart emails" do
      Row.standardize_google(STRUC_EMAILS, google_emails)
      google_emails["E-mail 1 - Value"].should eq("whim@whick.com")
      google_emails["E-mail 2 - Value"].should eq("whim@whuff.com")
    end
  end

  describe "removes duplicate email, phone, website info from rows" do
    let(:duplicates) {CSV.read(File.open(File.expand_path("../fixtures/contact_duplicates.csv", __FILE__)), headers: true)}
    let(:email_dups) {duplicates[0]}
    let(:phone_dups) {duplicates[1]}
    let(:website_dups) {duplicates[2]}
    let(:email_dups_no_types) {duplicates[3]}
    let(:address_dups) {duplicates[4]}
    let(:address_dups_2) {duplicates[5]}
    let(:address_dups_3) {duplicates[6]}
    let(:address_dups_4) {duplicates[8]}

    it "removes duplicate emails" do
      Row.remove_duplicates(STRUC_EMAILS, email_dups)
      Row.remove_duplicates(STRUC_EMAILS, email_dups_no_types)
      email_dups["E-mail 1 - Value"].should eq("myrtle@wood.com")
      email_dups["E-mail 1 - Type"].should eq("Home\nBusiness")
      email_dups["E-mail 2 - Value"].should eq("pacificsunrise@coast.com")
      email_dups_no_types["E-mail 1 - Value"].should eq("support@suppot.net")
    end
    it "removes duplicate phones" do
      Row.standardize_phones(phone_dups, FIELDS["phones"]["value"])
      Row.remove_duplicates(STRUC_PHONES, phone_dups)
      phone_dups["Phone 1 - Value"].should eq("'13125835832")
      phone_dups["Phone 1 - Type"].should eq("Mobile\nHome")
      phone_dups["Phone 2 - Value"].should eq("'18439992842")
    end
    it "removes duplicate addresses" do
      Row.remove_duplicates(STRUC_ADDRESSES, address_dups)
      address_dups["Address 1 - Street"].should eq("1180 Stony Marsh Blvd.")
      address_dups["Address 2 - Country"].should be_empty
      address_dups["Address 2 - Postal Code"].should be_empty
    end
    it "collapses addresses that are subsets of other addresses" do
      Row.remove_duplicates(STRUC_ADDRESSES, address_dups_2)
      Row.remove_duplicates(STRUC_ADDRESSES, address_dups_3)
      address_dups_2["Address 1 - Street"].should eq("1 Squid Lane")
      address_dups_2["Address 1 - City"].should eq("Kelp City")
      address_dups_2["Address 1 - Region"].should eq("Seaside")
      address_dups_2["Address 1 - Postal Code"].should eq("93523")
      address_dups_2["Address 1 - Country"].should eq("USA")
      address_dups_3["Address 1 - Street"].should eq("3 Mystery Mansion")
      address_dups_3["Address 1 - City"].should eq("Rocket")
      address_dups_3["Address 2 - Region"].should eq("")
      address_dups_3["Address 2 - Country"].should eq("")
      address_dups_3["Address 3 - Region"].should eq("")
      address_dups_3["Address 3 - Country"].should eq("")
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