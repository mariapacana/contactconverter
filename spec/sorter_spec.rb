require 'rspec'
require 'yaml'
require 'csv'

require_relative '../sorter'
require_relative '../constants'

include Constants

describe Sorter do

  describe "can sort addresses" do
    describe "for SageAct formats\n" do
      let (:address_headers_work) {['SA - Address 1','SA - Address 2','SA - Address 3', 'Address 1 - City', 'Address 1 - Region', 'Address 1 - Street', 'Address 1 - Postal Code', 'Address 1 - PO Box']}
      let (:address_headers_home) {['SA - Home Address 1','SA - Home Address 2','SA - Home Address 3', 'Address 2 - City', 'Address 2 - Region', 'Address 2 - Street', 'Address 2 - Postal Code', 'Address 2 - PO Box']}

      describe "can identify zip codes" do
        let (:a2_is_zip1) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', '94183', '', '', '', '', '',''])}
        let (:a2_is_zip2) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', '94183-9999', '', '', '', '', '',''])} 
        it "sets address 2 to postal code if address 2 is a 5-digit postal code" do
          Sorter.sort_address(a2_is_zip1, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_zip1["Address 1 - Postal Code"].should eq('94183')
          a2_is_zip1['Address 1 - Street'].should eq('33 Mayfair Road')
        end
        it "sets address 2 to postal code if address 2 is a 9-digit postal code" do
          Sorter.sort_address(a2_is_zip2, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_zip2["Address 1 - Postal Code"].should eq('94183-9999')
        end
      end
      describe "can identify city / region / zips" do
        let (:a2_is_address1) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'Long Island City, N.Y., 11104', '', '', '', '', '',''])}
        let (:a2_is_address2) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'Long Island City, NY, 11104', '', '', '', '', '',''])}
        let (:a2_is_address3) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'Long Island City NY 11104', '', '', '', '', '',''])}

        it "sets city, region (with periods), & zip if in address 2" do
          Sorter.sort_address(a2_is_address1, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_address1['Address 1 - City'].should eq('Long Island City')
          a2_is_address1['Address 1 - Region'].should eq('N.Y.')
          a2_is_address1['Address 1 - Postal Code'].should eq('11104')
        end
        it "sets city, region (no periods), & zip if in address 2" do
          Sorter.sort_address(a2_is_address2, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_address2['Address 1 - City'].should eq('Long Island City')
          a2_is_address2['Address 1 - Region'].should eq('NY')
          a2_is_address2['Address 1 - Postal Code'].should eq('11104')
          a2_is_address2['Address 1 - Street'].should eq('33 Mayfair Road')
        end
        it "sets city, region (no periods), & zip (sep on \s) if in address 2" do
          Sorter.sort_address(a2_is_address3, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_address3['Address 1 - City'].should eq('Long Island City')
          a2_is_address3['Address 1 - Region'].should eq('NY')
          a2_is_address3['Address 1 - Postal Code'].should eq('11104')
        end
      end
      describe "can identify PO Boxes" do
        let (:a2_is_po_box1) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'P.O. Box 435', '', '', '', '', '',''])}
        let (:a2_is_po_box2) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'PO Box 435', '', '', '', '', '',''])}
        let (:a2_is_po_box_address) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', 'PO Box 437 Cincinnati OH 30148', '', '', '', '', '',''])}

        it "sets po box (with periods) if in address 2" do
          Sorter.sort_address(a2_is_po_box1, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_po_box1['Address 1 - PO Box'].should eq('P.O. Box 435')
        end
        it "sets po box (no periods) if in address 2" do
          Sorter.sort_address(a2_is_po_box2, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_po_box2['Address 1 - PO Box'].should eq('PO Box 435')
        end
        it "sets po box, city, region (no periods), & zip (sep on \s) if in address 2" do
          Sorter.sort_address(a2_is_po_box_address, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_po_box_address['Address 1 - PO Box'].should eq('PO Box 437')
          a2_is_po_box_address['Address 1 - City'].should eq('Cincinnati')
          a2_is_po_box_address['Address 1 - Region'].should eq('OH')
          a2_is_po_box_address['Address 1 - Postal Code'].should eq('30148')
        end
      end
      describe "can identify streets" do
        let (:a2_is_street_address) {CSV::Row.new(address_headers_work, ['Wilbur Hotel', '65 Sneath Lane', '', '', '', '', '',''])}

        it "merges together address 1 and address 2" do
          Sorter.sort_address(a2_is_street_address, "work", SA_STRUC_ADDRESSES["work"])
          a2_is_street_address['Address 1 - Street'].should eq("Wilbur Hotel\n65 Sneath Lane")
        end
      end
      describe "can identify everything else" do
        let (:a3_is_address1) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', '','Long Island City, N.Y., 11104', '', '', '', '',''])}
        let (:a2_and_a3_exist) {CSV::Row.new(address_headers_work, ['c/o Harry Burrows', 'Wilbur Hotel', '65 Sneath Lane', '', '', '', '',''])}
        let (:a2_is_zip1_home) {CSV::Row.new(address_headers_home, ['33 Mayfair Road', '94183', '', '', '', '', '',''])}
        let (:a1_address_home) {CSV::Row.new(address_headers_home, ['Bronx River Houses, New York, United States', '94183', '', '', '', '', '',''])}
        it "sets city, region (with periods), & zip if in address 3" do
          Sorter.sort_address(a3_is_address1, "work", SA_STRUC_ADDRESSES["work"])
          a3_is_address1['Address 1 - City'].should eq('Long Island City')
          a3_is_address1['Address 1 - Region'].should eq('N.Y.')
          a3_is_address1['Address 1 - Postal Code'].should eq('11104')
        end
        it "merges together address 1, address 2, and address 3" do
          Sorter.sort_address(a2_and_a3_exist, "work", SA_STRUC_ADDRESSES["work"])
          a2_and_a3_exist['Address 1 - Street'].should eq("c/o Harry Burrows\nWilbur Hotel\n65 Sneath Lane")
        end
        it "sets address 2 to postal code if address 2 is a 5-digit postal code" do
          Sorter.sort_address(a2_is_zip1_home, "home", SA_STRUC_ADDRESSES["home"])
          a2_is_zip1_home["Address 2 - Postal Code"].should eq('94183')
          a2_is_zip1_home['Address 2 - Street'].should eq('33 Mayfair Road')
        end
        it "sets address 2 to postal code if address 2 is a 5-digit postal code" do
          Sorter.sort_address(a1_address_home, "home", SA_STRUC_ADDRESSES["home"])
          a1_address_home['Address 2 - Street'].should eq('Bronx River Houses, New York, United States')
        end
      end
    end

    describe "when there are two address lines" do
      describe "in the case of iCloud" do
        let (:address_headers_work) {['IC - Business Address', 'IC - Business Address2', 'Address 1 - City', 'Address 1 - Region', 'Address 1 - Street', 'Address 1 - Postal Code', 'Address 1 - PO Box']}
        let (:a2_is_zip1) {CSV::Row.new(address_headers_work, ['33 Mayfair Road', '94183', '', '', '', '', ''])}
        let (:a1_is_po_box) {CSV::Row.new(address_headers_work, [" PO Box 671252", '', '', '', '', '', ''])}
        let (:a1_is_po_box_street) {CSV::Row.new(address_headers_work, [" P.O. Box 457\n1615 Robertson Road", '', '', '', '', '', ''])}
        let (:a1_is_full_address) {CSV::Row.new(address_headers_work, ["  302 Sheffield Ave.\nBrooklyn, NY 11207  (Betwen Belmont Ave and Sutter Ave.)", '', '', '', '', '', ''])}
        let (:a1_is_street_address) {CSV::Row.new(address_headers_work, ["3333 Golden Gate Ave.", '', '', '', '', '', ''])}
        let (:a2_is_city_state_zip) {CSV::Row.new(address_headers_work, [" \nBrooklyn, NY 11207  (Betwen Belmont Ave and Sutter Ave.)", '', '', '', '', '', ''])} 
        let (:a2_is_city_state_zip2) {CSV::Row.new(address_headers_work, [" \nKingston, ON, K7P2E4", '', '', '', '', '', ''])} 
        let (:a2_is_city_state_zip3) {CSV::Row.new(address_headers_work, [" \nLong Island City,NY 11101", '', '', '', '', '', ''])} 
        let (:a1_a2_messed_up) {CSV::Row.new(address_headers_work, ['Wilbur Hotel', 'Wilburmania', '', '', '', '', ''])}
        it "sets address 2 to postal code if address 2 is a 5-digit postal code" do
          Sorter.sort_address(a2_is_zip1, "work", IC_STRUC_ADDRESSES["work"])
          a2_is_zip1["Address 1 - Postal Code"].should eq('94183')
          a2_is_zip1['Address 1 - Street'].should eq('33 Mayfair Road')
        end
        it "sets address 1 to PO Box if address 1 is a PO box" do
          Sorter.sort_address(a1_is_po_box, "work", IC_STRUC_ADDRESSES["work"])
          a1_is_po_box["Address 1 - PO Box"].should eq('PO Box 671252')
        end
        it "sets address 1 to PO Box and street if address 1 is a PO box" do
          Sorter.sort_address(a1_is_po_box_street, "work", IC_STRUC_ADDRESSES["work"])
          a1_is_po_box_street["Address 1 - PO Box"].should eq('P.O. Box 457')
          a1_is_po_box_street["Address 1 - Street"].should eq('1615 Robertson Road')
        end
        it "sets city state zip 2" do
          Sorter.sort_address(a2_is_city_state_zip, "work", IC_STRUC_ADDRESSES["work"])
          a2_is_city_state_zip["Address 1 - City"] = "Brooklyn"
          a2_is_city_state_zip["Address 1 - Region"] = "NY"
          a2_is_city_state_zip["Address 1 - Postal Code"] = "11207"
        end
        it "sets city state zip 2" do
          Sorter.sort_address(a2_is_city_state_zip2, "work", IC_STRUC_ADDRESSES["work"])
          a2_is_city_state_zip2["Address 1 - City"] = "Kingston"
          a2_is_city_state_zip2["Address 1 - Region"] = "ON"
          a2_is_city_state_zip2["Address 1 - Postal Code"] = "K7P2E4"
        end
        it "sets city state zip 2" do
          Sorter.sort_address(a2_is_city_state_zip3, "work", IC_STRUC_ADDRESSES["work"])
          a2_is_city_state_zip3["Address 1 - City"] = "Long Island City"
          a2_is_city_state_zip3["Address 1 - Region"] = "NY"
          a2_is_city_state_zip3["Address 1 - Postal Code"] = "11101"
        end
        it "splits apart full address if it's all in a1" do
          Sorter.sort_address(a1_is_full_address, "work", IC_STRUC_ADDRESSES["work"])
          a1_is_full_address["Address 1 - Street"].should eq("302 Sheffield Ave.")
          a1_is_full_address["Address 1 - City"].should eq("Brooklyn")
          a1_is_full_address["Address 1 - Region"].should eq("NY")
          a1_is_full_address["Address 1 - Postal Code"].should eq("11207")
        end
        it "joins together the addresses if they weren't sorted" do
          Sorter.sort_address(a1_a2_messed_up, "work", IC_STRUC_ADDRESSES["work"])
          a1_a2_messed_up["Address 1 - Street"].should eq("Wilbur Hotel\nWilburmania")
        end
        it "puts a1 in street address if it was street address" do
          Sorter.sort_address(a1_is_street_address, "work", IC_STRUC_ADDRESSES["work"])
          a1_is_street_address["Address 1 - Street"].should eq("3333 Golden Gate Ave.")
        end
      end
    end
  end

  describe "in the case of extensions" do
    describe "in the case of SageAct" do
      let (:ext1) {CSV::Row.new(['Phone 2 - Value', 'SA - Mobile Extension'], ['773-333-4444', '2343'])}
      let (:ext2) {CSV::Row.new(['Phone 1 - Value', 'Phone 2 - Value', 'SA - Alternate Phone', 'SA - Alternate Extension'], ['', '', '773-333-4444', '2343'])}
      it "sticks the extension on the phone" do
        Sorter.sort_extensions(ext1, SA_STRUC_EXTENSIONS)
        ext1['Phone 2 - Value'].should eq('773-333-4444 Extension: 2343')
      end
      it "assigns the alternate phone to a blank phone" do
        Sorter.sort_extensions(ext2, SA_STRUC_EXTENSIONS)
        ext2['Phone 1 - Value'].should eq('773-333-4444 Extension: 2343')
      end
    end
  end
end