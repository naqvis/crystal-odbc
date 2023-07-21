class ODBC::ResultSet < DB::ResultSet
  def initialize(@statement, @stmt_handle : LibODBC::Sqlhandle)
    super(@statement)
    @column_index = 1
  end

  def move_next : Bool
    @column_index = 1
    # Special check in case there was no result set generated
    return false if column_count == 0

    # Fetch the next row
    ret = LibODBC.sql_fetch(@stmt_handle)
    return false if ret == LibODBC::SQL_NO_DATA
    check(ret)
    true
  end

  def read
    col = @column_index
    @column_index += 1

    # Get the type of the column
    check LibODBC.sql_col_attribute_w(@stmt_handle, col, LibODBC::SQL_DESC_CONCISE_TYPE, nil, 0, nil, out col_type)

    # Query the data from the column
    ind_ptr = 0_i64
    case col_type
          when LibODBC::SQL_BIT
            bit = uninitialized UInt8
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BIT, pointerof(bit), 0, pointerof(ind_ptr))
            ind_ptr == LibODBC::SQL_NULL_DATA ? nil : (bit == 0 ? false : true)
          when LibODBC::SQL_TINYINT
            tval = uninitialized UInt8
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TINYINT, pointerof(tval), 0, pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA

            ind_ptr == 1 ? (tval == 1) : tval
          when LibODBC::SQL_SMALLINT, LibODBC::SQL_INTEGER, LibODBC::SQL_BIGINT
            ival = uninitialized Int64
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_SBIGINT, pointerof(ival), 0, pointerof(ind_ptr))
            ind_ptr == LibODBC::SQL_NULL_DATA ? nil : ival
          when LibODBC::SQL_REAL, LibODBC::SQL_FLOAT, LibODBC::SQL_DOUBLE, LibODBC::SQL_NUMERIC, LibODBC::SQL_DECIMAL
            fval = uninitialized Float64
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_DOUBLE, pointerof(fval), 0, pointerof(ind_ptr))
            ind_ptr == LibODBC::SQL_NULL_DATA ? nil : fval
          when LibODBC::SQL_CHAR, LibODBC::SQL_VARCHAR, LibODBC::SQL_LONGVARCHAR
            dummy = Bytes.new(1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_CHAR, dummy.to_unsafe, 0, pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA
            slen = ind_ptr
            sbuf = Bytes.new(slen + 1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_CHAR, sbuf.to_unsafe, sbuf.size, pointerof(ind_ptr))
            String.new(sbuf[...slen])
          when LibODBC::SQL_WCHAR, LibODBC::SQL_WVARCHAR, LibODBC::SQL_WLONGVARCHAR
            dummy = Bytes.new(1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, dummy.to_unsafe, 0, pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA
            slen = (ind_ptr / 2).to_i
            sbuf = Slice(UInt16).new(slen + 1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, sbuf.to_unsafe, (slen + 1)*2, pointerof(ind_ptr))
            String.from_utf16(sbuf[...slen])
          when LibODBC::SQL_GUID
            slen = 36
            sbuf = Slice(UInt16).new(slen + 1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, sbuf.to_unsafe, (slen + 1)*2, pointerof(ind_ptr))
            ind_ptr == LibODBC::SQL_NULL_DATA ? nil : String.from_utf16(sbuf[...slen])
          when LibODBC::SQL_BINARY, LibODBC::SQL_VARBINARY, LibODBC::SQL_LONGVARBINARY
            dummy = Bytes.new(1)
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BINARY, dummy.to_unsafe, 0, pointerof(ind_ptr))
            if ind_ptr == LibODBC::SQL_NULL_DATA
              nil
            else
              sbuf = Bytes.new(ind_ptr.to_i)
              check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BINARY, sbuf.to_unsafe, ind_ptr + 1, pointerof(ind_ptr))
              sbuf
            end
          when LibODBC::SQL_TYPE_DATE
            dt = uninitialized LibODBC::Date
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_DATE, pointerof(dt), sizeof(typeof(dt)), pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA
            Time.local(year: dt.year.to_i, month: dt.month.to_i, day: dt.day.to_i, location: Time::Location::UTC)
          when LibODBC::SQL_TYPE_TIME
            tm = uninitialized LibODBC::Time
            now = Time.utc

            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_TIME, pointerof(tm), sizeof(typeof(tm)), pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA
            Time.local(year: now.year.to_i, month: now.month.to_i, day: now.day.to_i, hour: tm.hour.to_i, minute: tm.minute.to_i, second: tm.second.to_i, location: Time::Location::UTC)
          when LibODBC::SQL_TYPE_TIMESTAMP
            tsv = uninitialized LibODBC::TimeStamp
            check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_TIMESTAMP, pointerof(tsv), sizeof(typeof(tsv)), pointerof(ind_ptr))
            return nil if ind_ptr == LibODBC::SQL_NULL_DATA
            Time.local(year: tsv.year.to_i, month: tsv.month.to_i, day: tsv.day.to_i,
              hour: tsv.hour.to_i, minute: tsv.minute.to_i, second: tsv.second.to_i,
              nanosecond: tsv.fraction.to_i, location: Time::Location::UTC)
          else
            nil
          end
  end

  def read(t : Int32.class) : Int32
    read(Int64).to_i32
  end

  def read(type : Int32?.class) : Int32?
    read(Int64?).try &.to_i32
  end

  def read(t : Float32.class) : Float32
    read(Float64).to_f32
  end

  def read(type : Float32?.class) : Float32?
    read(Float64?).try &.to_f32
  end

  def column_count : Int32
    check LibODBC.sql_num_result_cols(@stmt_handle, out count)
    count.to_i
  end

  def column_name(index : Int32) : String
    # get the length of the column name
    index += 1
    check LibODBC.sql_col_attribute_w(@stmt_handle, index.to_i16, LibODBC::SQL_DESC_NAME, nil, 0, out len, nil)

    # If the name length is 0, skip getting the name (the default is empty anyway)
    col_name_len = (len / 2).to_i
    return "" if col_name_len == 0

    # Get the column name
    col_name = Slice(UInt16).new(col_name_len + 1)
    check LibODBC.sql_col_attribute_w(@stmt_handle, index.to_i16, LibODBC::SQL_DESC_NAME, col_name.to_unsafe, (col_name_len + 1)*2, nil, nil)

    String.from_utf16 col_name[...col_name_len]
  end

  def next_column_index : Int32
    @column_index - 1
  end

  protected def do_close
    super
    check LibODBC.sql_close_cursor(@stmt_handle)

    # Unprepared statements do_close are not called by DB api, so we have to call it manually
    if @statement.is_a?(UnPreparedStatement) && (ups = @statement.as?(UnPreparedStatement))
      ups.do_close
    end
  end

  private def get_name(col)
    fname = Bytes.new(256)
    check LibODBC.sql_col_attribute(@stmt_handle, col, LibODBC::SQL_DESC_TYPE_NAME, fname.to_unsafe, fname.size, out flen, out col_type)
    String.new(fname[...flen])
  end

  private def check(code)
    ODBC.check code do
      err = ODBC.get_errors(ErrorType::STMT, @stmt_handle)
      raise Error.from_status(err)
    end
    code
  end
end
