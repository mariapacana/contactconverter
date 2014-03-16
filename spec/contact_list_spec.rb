require 'rspec'

require_relative '../contact_list'

describe ContactList do

  let (:icloud) {ContactList.new(source_file: File.expand_path("../fixtures/icloud_fixture.csv", __FILE__),
                                 config_file: File.expand_path("../../icloud.yaml", __FILE__))}
  let (:g_headers) {  YAML.load(File.open(File.expand_path("../../google.yaml", __FILE__))) }

  describe "#headers_in_order" do
    it "should put all of the headers in order" do
      (g_headers - icloud.headers_in_order.headers).should be_empty
    end
  end

  describe "#delete_blank_columns" do
    it "should remove blank columns" do
      icloud.delete_blank_columns
      icloud.headers.should_not include("Nickname")
    end
  end

  describe "#remove_sparse_contacts" do
    it "should remove contacts without info" do
      icloud.remove_sparse_contacts
      icloud.contacts["IC - id"]. should_not include("pas-id-53095B97000023B7")
    end
  end

  describe "#process_fields" do
    it "should standardize phone numbers" do
      icloud.process_fields
      icloud.save_to_file("formattedicloud.csv")
    end
  end

end