require 'rspec'

require_relative '../row'

describe Row do

  PHONES = ["Phone 1 - Value", "Phone 1 - Type", "Phone 2 - Value", "Phone 2 - Type", "Phone 3 - Value", "Phone 3 - Type", "Phone 4 - Value", "Phone 4 - Type", "Phone 5 - Value", "Phone 5 - Type"]

  let (:contact_1) {CSV::Row.new(PHONES, ["(312) 838-3923", nil, "(312) 838-3923", nil, "(312) 838-3443", nil,"(312) 234-3237", nil,"(312) 658-3923", nil,])}

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

end