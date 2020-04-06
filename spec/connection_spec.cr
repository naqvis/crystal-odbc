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
end
