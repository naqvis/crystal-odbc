require "./spec_helper"

describe Driver do
  it "should register odbc name" do
    DB.driver_class("odbc").should eq(ODBC::Driver)
  end

  it "should use database option as file to open" do
    with_db do |db|
      db.driver.should be_a(ODBC::Driver)
      File.exists?(DB_FILENAME).should be_true
    end
  end
end
