require "./spec_helper"

describe ODBC::Config do
  after_each do
    ODBC::Config.reset!
  end

  it "has sensible defaults" do
    config = ODBC::Config.new
    config.connection_timeout.should eq(30.seconds)
    config.query_timeout.should eq(30.seconds)
    config.login_timeout.should eq(15.seconds)
    config.enable_tracing?.should be_false
    config.default_buffer_size.should eq(8192)
    config.max_string_length.should eq(65536)
    config.auto_commit?.should be_true
  end

  it "provides a singleton instance" do
    a = ODBC::Config.instance
    b = ODBC::Config.instance
    a.should be(b)
  end

  it "allows programmatic configuration" do
    ODBC::Config.configure do |c|
      c.connection_timeout = 60.seconds
      c.query_timeout = 10.seconds
      c.login_timeout = 5.seconds
      c.auto_commit = false
    end

    config = ODBC::Config.instance
    config.connection_timeout.should eq(60.seconds)
    config.query_timeout.should eq(10.seconds)
    config.login_timeout.should eq(5.seconds)
    config.auto_commit?.should be_false
  end

  it "resets to defaults" do
    ODBC::Config.configure do |c|
      c.connection_timeout = 99.seconds
    end
    ODBC::Config.instance.connection_timeout.should eq(99.seconds)

    ODBC::Config.reset!
    ODBC::Config.instance.connection_timeout.should eq(30.seconds)
  end
end

describe "ODBC environment handle" do
  it "returns a non-null handle" do
    handle = ODBC.env_handle
    handle.should_not be_nil
  end

  it "returns the same handle on repeated calls" do
    a = ODBC.env_handle
    b = ODBC.env_handle
    a.should eq(b)
  end

  it "is safe to call from multiple fibers" do
    channel = Channel(LibODBC::Sqlhandle).new
    10.times do
      spawn do
        channel.send(ODBC.env_handle)
      end
    end

    handles = Array(LibODBC::Sqlhandle).new
    10.times { handles << channel.receive }

    handles.uniq.size.should eq(1)
  end
end

describe "ODBC connection errors" do
  it "raises on invalid DSN" do
    expect_raises(ODBC::Error) do
      DB.connect "odbc://Driver=NONEXISTENT_DRIVER;Database=nope.db"
    end
  end

  it "raises on malformed connection string" do
    expect_raises(ODBC::Error) do
      DB.connect "odbc://;;;===;;;"
    end
  end
end

describe "ODBC connection" do
  it "reports alive connection" do
    with_cnn do |cnn|
      odbc_cnn = cnn.as(ODBC::Connection)
      odbc_cnn.connection_alive?.should be_true
    end
  end

  it "detects driver capabilities" do
    with_cnn do |cnn|
      odbc_cnn = cnn.as(ODBC::Connection)
      odbc_cnn.odbc_driver_name.should_not eq("Unknown")
      odbc_cnn.max_identifier_length.should be > 0
    end
  end
end

describe "ODBC column names" do
  it "retrieves column names correctly" do
    with_db do |db|
      db.exec "create table col_test (first_name text, last_name text, age integer)"
      db.exec "insert into col_test values ('a', 'b', 1)"
      db.query "select first_name, last_name, age from col_test" do |rs|
        rs.move_next
        rs.column_name(0).should eq("first_name")
        rs.column_name(1).should eq("last_name")
        rs.column_name(2).should eq("age")
      end
    end
  end

  it "handles single character column names" do
    with_db do |db|
      db.exec "create table short_col (x integer)"
      db.exec "insert into short_col values (1)"
      db.query "select x from short_col" do |rs|
        rs.move_next
        rs.column_name(0).should eq("x")
      end
    end
  end

  it "handles long column names" do
    with_db do |db|
      long_name = "a_very_long_column_name_that_tests_buffer_handling"
      db.exec "create table long_col (#{long_name} integer)"
      db.exec "insert into long_col values (42)"
      db.query "select #{long_name} from long_col" do |rs|
        rs.move_next
        rs.column_name(0).should eq(long_name)
      end
    end
  end
end

describe "ODBC NULL handling" do
  it "reads NULL integer" do
    with_db do |db|
      db.exec "create table null_int (val integer)"
      db.exec "insert into null_int values (null)"
      db.query "select val from null_int" do |rs|
        rs.move_next
        rs.read(Int64?).should be_nil
      end
    end
  end

  it "reads NULL string" do
    with_db do |db|
      db.exec "create table null_str (val text)"
      db.exec "insert into null_str values (null)"
      db.query "select val from null_str" do |rs|
        rs.move_next
        rs.read(String?).should be_nil
      end
    end
  end

  it "reads NULL float" do
    with_db do |db|
      db.exec "create table null_flt (val float)"
      db.exec "insert into null_flt values (null)"
      db.query "select val from null_flt" do |rs|
        rs.move_next
        rs.read(Float64?).should be_nil
      end
    end
  end

  it "reads NULL in a row with non-null values" do
    with_db do |db|
      db.exec "create table mixed_null (name text, age integer, score float)"
      db.exec "insert into mixed_null values ('alice', null, 9.5)"
      db.query "select name, age, score from mixed_null" do |rs|
        rs.move_next
        rs.read(String).should eq("alice")
        rs.read(Int64?).should be_nil
        rs.read(Float64).should eq(9.5)
      end
    end
  end

  it "reads all-NULL row" do
    with_db do |db|
      db.exec "create table all_null (a text, b integer, c float)"
      db.exec "insert into all_null values (null, null, null)"
      db.query "select a, b, c from all_null" do |rs|
        rs.move_next
        rs.read(String?).should be_nil
        rs.read(Int64?).should be_nil
        rs.read(Float64?).should be_nil
      end
    end
  end
end

describe "ODBC empty results" do
  it "handles empty result set from SELECT" do
    with_db do |db|
      db.exec "create table empty_tbl (val integer)"
      count = 0
      db.query "select val from empty_tbl" do |rs|
        rs.each { count += 1 }
      end
      count.should eq(0)
    end
  end

  it "handles count on empty table" do
    with_db do |db|
      db.exec "create table empty_count (val integer)"
      db.scalar("select count(*) from empty_count").should eq(0_i64)
    end
  end
end

describe "ODBC string handling" do
  it "reads empty string" do
    with_db do |db|
      db.exec "create table empty_str (val text)"
      db.exec "insert into empty_str values ('')"
      db.query "select val from empty_str" do |rs|
        rs.move_next
        rs.read(String).should eq("")
      end
    end
  end

  it "reads string with special characters" do
    with_db do |db|
      db.exec "create table special_str (val text)"
      db.exec "insert into special_str values (?)", "hello 'world' \"test\" \\ / \n\t"
      db.query "select val from special_str" do |rs|
        rs.move_next
        val = rs.read(String)
        val.should contain("hello")
        val.should contain("world")
      end
    end
  end

  it "reads unicode strings" do
    with_db do |db|
      db.exec "create table unicode_str (val text)"
      db.exec "insert into unicode_str values (?)", "café résumé naïve"
      db.query "select val from unicode_str" do |rs|
        rs.move_next
        rs.read(String).should eq("café résumé naïve")
      end
    end
  end

  it "reads large string near buffer boundary" do
    with_db do |db|
      db.exec "create table large_str (val text)"
      large = "x" * 8192
      db.exec "insert into large_str values (?)", large
      db.query "select val from large_str" do |rs|
        rs.move_next
        rs.read(String).should eq(large)
      end
    end
  end

  it "reads string larger than default buffer" do
    with_db do |db|
      db.exec "create table xlarge_str (val text)"
      xlarge = "y" * 16384
      db.exec "insert into xlarge_str values (?)", xlarge
      db.query "select val from xlarge_str" do |rs|
        rs.move_next
        rs.read(String).should eq(xlarge)
      end
    end
  end
end

describe "ODBC numeric handling" do
  it "reads zero" do
    with_db do |db|
      db.exec "create table zero_val (val integer)"
      db.exec "insert into zero_val values (0)"
      db.query "select val from zero_val" do |rs|
        rs.move_next
        rs.read(Int64).should eq(0_i64)
      end
    end
  end

  it "reads negative integers" do
    with_db do |db|
      db.exec "create table neg_int (val integer)"
      db.exec "insert into neg_int values (?)", -42_i64
      db.query "select val from neg_int" do |rs|
        rs.move_next
        rs.read(Int64).should eq(-42_i64)
      end
    end
  end

  it "reads large integers" do
    with_db do |db|
      db.exec "create table big_int (val integer)"
      big = 2_147_483_647_i64
      db.exec "insert into big_int values (?)", big
      db.query "select val from big_int" do |rs|
        rs.move_next
        rs.read(Int64).should eq(big)
      end
    end
  end

  it "reads very small float" do
    with_db do |db|
      db.exec "create table small_flt (val float)"
      db.exec "insert into small_flt values (?)", 0.000001
      db.query "select val from small_flt" do |rs|
        rs.move_next
        rs.read(Float64).should be_close(0.000001, 1e-9)
      end
    end
  end

  it "reads negative float" do
    with_db do |db|
      db.exec "create table neg_flt (val float)"
      db.exec "insert into neg_flt values (?)", -3.14
      db.query "select val from neg_flt" do |rs|
        rs.move_next
        rs.read(Float64).should be_close(-3.14, 0.001)
      end
    end
  end
end

describe "ODBC type coercion" do
  it "reads integer column as Int32" do
    with_db do |db|
      db.exec "create table coerce_i32 (val integer)"
      db.exec "insert into coerce_i32 values (42)"
      db.query "select val from coerce_i32" do |rs|
        rs.move_next
        rs.read(Int32).should eq(42)
      end
    end
  end

  it "reads integer column as Float64" do
    with_db do |db|
      db.exec "create table coerce_f64 (val integer)"
      db.exec "insert into coerce_f64 values (7)"
      db.query "select val from coerce_f64" do |rs|
        rs.move_next
        rs.read(Float64).should eq(7.0)
      end
    end
  end

  it "reads float column as Float32" do
    with_db do |db|
      db.exec "create table coerce_f32 (val float)"
      db.exec "insert into coerce_f32 values (2.5)"
      db.query "select val from coerce_f32" do |rs|
        rs.move_next
        rs.read(Float32).should be_close(2.5_f32, 0.01)
      end
    end
  end
end

describe "ODBC parameter binding" do
  it "binds NULL parameter" do
    with_db do |db|
      db.exec "create table bind_null (val text)"
      db.exec "insert into bind_null values (?)", nil
      db.query "select val from bind_null" do |rs|
        rs.move_next
        rs.read(String?).should be_nil
      end
    end
  end

  it "binds boolean true" do
    with_db do |db|
      db.exec "create table bind_bool (val tinyint)"
      db.exec "insert into bind_bool values (?)", true
      db.query "select val from bind_bool" do |rs|
        rs.move_next
        rs.read(Bool).should be_true
      end
    end
  end

  it "binds boolean false" do
    with_db do |db|
      db.exec "create table bind_bool_f (val tinyint)"
      db.exec "insert into bind_bool_f values (?)", false
      db.query "select val from bind_bool_f" do |rs|
        rs.move_next
        rs.read(Bool).should be_false
      end
    end
  end

  it "binds empty string" do
    with_db do |db|
      db.exec "create table bind_empty (val text)"
      db.exec "insert into bind_empty values (?)", ""
      db.query "select val from bind_empty" do |rs|
        rs.move_next
        rs.read(String).should eq("")
      end
    end
  end

  it "binds Time parameter" do
    with_db do |db|
      db.exec "create table bind_time (val datetime)"
      t = Time.utc(2024, 12, 25, 10, 30, 0)
      db.exec "insert into bind_time values (?)", t
      db.query "select val from bind_time" do |rs|
        rs.move_next
        result = rs.read(Time)
        result.year.should eq(2024)
        result.month.should eq(12)
        result.day.should eq(25)
      end
    end
  end

  it "raises on wrong parameter count" do
    with_db do |db|
      db.exec "create table bind_count (a integer, b integer)"
      expect_raises(ODBC::Error) do
        db.exec "insert into bind_count values (?, ?)", 1
      end
    end
  end
end

describe "ODBC statement reuse" do
  it "executes the same prepared statement multiple times" do
    with_db do |db|
      db.exec "create table reuse_stmt (val integer)"
      3.times do |i|
        db.exec "insert into reuse_stmt values (?)", i
      end
      db.scalar("select count(*) from reuse_stmt").should eq(3_i64)
    end
  end
end

describe "ODBC transactions" do
  it "rolls back on exception" do
    with_db do |db|
      db.exec "create table txn_test (val integer)"
      db.exec "insert into txn_test values (1)"

      expect_raises(Exception) do
        db.transaction do |tx|
          conn = tx.connection
          conn.exec "insert into txn_test values (2)"
          raise "deliberate error"
        end
      end

      db.scalar("select count(*) from txn_test").should eq(1_i64)
    end
  end

  it "commits on success" do
    with_db do |db|
      db.exec "create table txn_commit (val integer)"

      db.transaction do |tx|
        conn = tx.connection
        conn.exec "insert into txn_commit values (1)"
        conn.exec "insert into txn_commit values (2)"
      end

      db.scalar("select count(*) from txn_commit").should eq(2_i64)
    end
  end
end

describe "ODBC rows_affected" do
  it "reports correct rows_affected for insert" do
    with_db do |db|
      db.exec "create table affected_test (val integer)"
      result = db.exec "insert into affected_test values (1)"
      result.rows_affected.should eq(1)
    end
  end

  it "reports correct rows_affected for update" do
    with_db do |db|
      db.exec "create table affected_upd (val integer)"
      db.exec "insert into affected_upd values (1)"
      db.exec "insert into affected_upd values (2)"
      db.exec "insert into affected_upd values (3)"
      result = db.exec "update affected_upd set val = 99 where val > 1"
      result.rows_affected.should eq(2)
    end
  end

  it "reports correct rows_affected for delete" do
    with_db do |db|
      db.exec "create table affected_del (val integer)"
      db.exec "insert into affected_del values (1)"
      db.exec "insert into affected_del values (2)"
      result = db.exec "delete from affected_del"
      result.rows_affected.should eq(2)
    end
  end

  it "reports zero rows_affected when nothing matches" do
    with_db do |db|
      db.exec "create table affected_zero (val integer)"
      result = db.exec "delete from affected_zero where val = 999"
      result.rows_affected.should eq(0)
    end
  end
end

describe "ODBC multi-row queries" do
  it "reads multiple rows correctly" do
    with_db do |db|
      db.exec "create table multi_row (id integer, name text)"
      db.exec "insert into multi_row values (1, 'alice')"
      db.exec "insert into multi_row values (2, 'bob')"
      db.exec "insert into multi_row values (3, 'charlie')"

      rows = db.query_all "select id, name from multi_row order by id", as: {Int64, String}
      rows.size.should eq(3)
      rows[0].should eq({1_i64, "alice"})
      rows[1].should eq({2_i64, "bob"})
      rows[2].should eq({3_i64, "charlie"})
    end
  end

  it "handles query_all on empty table" do
    with_db do |db|
      db.exec "create table empty_query_all (val integer)"
      rows = db.query_all "select val from empty_query_all", as: Int64
      rows.size.should eq(0)
    end
  end
end
