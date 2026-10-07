require "./spec_helper"

describe Connection do
  it "opens a connection without the pool" do
    with_cnn do |cnn|
      cnn.should be_a(ODBC::Connection)

      cnn.exec "create table person (name text, age integer)"
      cnn.exec "insert into person values (\"foo\", 10)"

      cnn.scalar("select count(*) from person").should eq(1)
    end
  end

  it "reports the driver name" do
    with_cnn do |cnn|
      cnn.driver_name.should eq("odbc")
    end
  end

  it "reports the name of the DBMS behind the ODBC driver" do
    with_cnn do |cnn|
      cnn.server_name.should eq("SQLite")
    end
  end

  it "reports the version of the DBMS behind the ODBC driver" do
    with_cnn do |cnn|
      cnn.server_version.should eq(cnn.scalar("select sqlite_version()"))
    end
  end
end
