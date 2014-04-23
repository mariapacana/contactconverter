require 'rspec'
require 'yaml'
require 'csv'
require 'pry'

require_relative '../util'
require_relative '../constants'

include Constants

describe Util do

  let(:ary) {["Maria\nPacana", "Herbert", nil, "von\nTrapp"]}
  let(:padded_ary) {["   Maria ", " Herbert"]}
  let(:my_hash) { {a: "1", b: nil}}

  it "checks to see if something is nil / blank / empty" do
    Util.nil_or_empty?([]).should eq(true)
    Util.nil_or_empty?("").should eq(true)
    Util.nil_or_empty?(nil).should eq(true)
    Util.nil_or_empty?("yip").should eq(false)
  end

  it "should join unique non-nil enum values on newlines" do
    new_ary = Util.join_and_format_uniques(ary)
    new_ary.should eq("Maria\nPacana\nHerbert\nvon\nTrapp")
  end

  it "should be able to delete nil values from an enum" do
    Util.not_nil(ary).should_not include(nil)
    Util.not_nil(ary).should_not include("")
  end

  it "should strip and join together vals with padding" do
    Util.join_and_strip(padded_ary).should eq("Maria\nHerbert")
  end

  xit "should flatten and get uniques" do
  end

  describe "set_value_if_nil" do
    it "shouldn't set hash values if they aren't nil" do
      Util.set_value_if_nil(my_hash, :a, "a")
      my_hash[:a].should eq("1")
    end
    it "should set hash values if they are nil" do
      Util.set_value_if_nil(my_hash, :b, "b")
      my_hash[:b].should eq("b")
    end
  end
end