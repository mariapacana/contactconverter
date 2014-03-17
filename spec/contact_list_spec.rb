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

  describe "#format_list" do
    it "should remove contacts without info" do
      icloud.format_list
      icloud.contacts["IC - id"]. should_not include("pas-id-53095B97000023B7")
    end
  end

end