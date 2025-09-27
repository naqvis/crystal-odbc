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

    # Try to read the value using the detected type, with fallbacks for driver compatibility
    read_column_value(col, col_type)
  end

  private def read_column_value(col : Int32, col_type : Int64)
    ind_ptr = 0_i64

    # Handle boolean/bit types
    if boolean_type?(col_type)
      return read_as_boolean(col, pointerof(ind_ptr))
    end

    # Handle integer types with fallbacks
    if integer_type?(col_type)
      return read_as_integer(col, col_type, pointerof(ind_ptr))
    end

    # Handle floating point types
    if float_type?(col_type)
      return read_as_float(col, pointerof(ind_ptr))
    end

    # Handle string types with encoding detection
    if string_type?(col_type)
      return read_as_string(col, col_type, pointerof(ind_ptr))
    end

    # Handle binary types
    if binary_type?(col_type)
      return read_as_binary(col, pointerof(ind_ptr))
    end

    # Handle date/time types
    if datetime_type?(col_type)
      return read_as_datetime(col, col_type, pointerof(ind_ptr))
    end

    # Handle GUID types
    if guid_type?(col_type)
      return read_as_guid(col, pointerof(ind_ptr))
    end

    # Fallback: try to read as string for unknown types
    read_as_string_fallback(col, pointerof(ind_ptr))
  end

  private def boolean_type?(col_type : Int64) : Bool
    col_type == LibODBC::SQL_BIT
  end

  private def integer_type?(col_type : Int64) : Bool
    case col_type
    when LibODBC::SQL_TINYINT, LibODBC::SQL_SMALLINT, LibODBC::SQL_INTEGER, LibODBC::SQL_BIGINT
      true
    else
      false
    end
  end

  private def float_type?(col_type : Int64) : Bool
    case col_type
    when LibODBC::SQL_REAL, LibODBC::SQL_FLOAT, LibODBC::SQL_DOUBLE, LibODBC::SQL_NUMERIC, LibODBC::SQL_DECIMAL
      true
    else
      false
    end
  end

  private def string_type?(col_type : Int64) : Bool
    case col_type
    when LibODBC::SQL_CHAR, LibODBC::SQL_VARCHAR, LibODBC::SQL_LONGVARCHAR,
         LibODBC::SQL_WCHAR, LibODBC::SQL_WVARCHAR, LibODBC::SQL_WLONGVARCHAR
      true
    else
      false
    end
  end

  private def binary_type?(col_type : Int64) : Bool
    case col_type
    when LibODBC::SQL_BINARY, LibODBC::SQL_VARBINARY, LibODBC::SQL_LONGVARBINARY
      true
    else
      false
    end
  end

  private def datetime_type?(col_type : Int64) : Bool
    case col_type
    when LibODBC::SQL_TYPE_DATE, LibODBC::SQL_TYPE_TIME, LibODBC::SQL_TYPE_TIMESTAMP,
         LibODBC::SQL_DATE, LibODBC::SQL_TIME, LibODBC::SQL_TIMESTAMP
      true
    else
      false
    end
  end

  private def guid_type?(col_type : Int64) : Bool
    col_type == LibODBC::SQL_GUID
  end

  private def read_as_boolean(col : Int32, ind_ptr : Pointer(Int64))
    bit = uninitialized UInt8
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BIT, pointerof(bit), 0, ind_ptr)

    # If bit type fails, try as tinyint (some drivers map boolean to tinyint)
    if !ODBC.success?(ret)
      tval = uninitialized UInt8
      check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TINYINT, pointerof(tval), 0, ind_ptr)
      return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
      return tval != 0
    end

    check ret
    ind_ptr.value == LibODBC::SQL_NULL_DATA ? nil : (bit == 0 ? false : true)
  end

  private def read_as_integer(col : Int32, col_type : Int64, ind_ptr : Pointer(Int64))
    case col_type
    when LibODBC::SQL_TINYINT
      tval = uninitialized UInt8
      ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TINYINT, pointerof(tval), 0, ind_ptr)
      if !ODBC.success?(ret)
        # Fallback to int32 for drivers that don't support tinyint properly
        return read_as_int32(col, ind_ptr)
      end
      check ret
      return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
      tval.to_i64
    when LibODBC::SQL_SMALLINT, LibODBC::SQL_INTEGER
      read_as_int32(col, ind_ptr)
    when LibODBC::SQL_BIGINT
      read_as_int64(col, ind_ptr)
    else
      # Fallback: try int64 first, then int32
      result = read_as_int64(col, ind_ptr)
      result.nil? ? read_as_int32(col, ind_ptr) : result
    end
  end

  private def read_as_int32(col : Int32, ind_ptr : Pointer(Int64))
    sival = uninitialized Int32
    check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_LONG, pointerof(sival), 0, ind_ptr)
    ind_ptr.value == LibODBC::SQL_NULL_DATA ? nil : sival.to_i64
  end

  private def read_as_int64(col : Int32, ind_ptr : Pointer(Int64))
    ival = uninitialized Int64
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_SBIGINT, pointerof(ival), 0, ind_ptr)
    if !ODBC.success?(ret)
      # Some drivers don't support SBIGINT, fallback to string and parse
      return read_integer_as_string(col, ind_ptr)
    end
    check ret
    ind_ptr.value == LibODBC::SQL_NULL_DATA ? nil : ival
  end

  private def read_integer_as_string(col : Int32, ind_ptr : Pointer(Int64))
    str_val = read_as_string_fallback(col, ind_ptr)
    return nil if str_val.nil?
    begin
      str_val.to_i64
    rescue ArgumentError
      nil
    end
  end

  private def read_as_float(col : Int32, ind_ptr : Pointer(Int64))
    fval = uninitialized Float64
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_DOUBLE, pointerof(fval), 0, ind_ptr)
    if !ODBC.success?(ret)
      # Fallback to string parsing for problematic drivers
      str_val = read_as_string_fallback(col, ind_ptr)
      return nil if str_val.nil?
      begin
        return str_val.to_f64
      rescue ArgumentError
        return nil
      end
    end
    check ret
    ind_ptr.value == LibODBC::SQL_NULL_DATA ? nil : fval
  end

  private def read_as_string(col : Int32, col_type : Int64, ind_ptr : Pointer(Int64))
    case col_type
    when LibODBC::SQL_WCHAR, LibODBC::SQL_WVARCHAR, LibODBC::SQL_WLONGVARCHAR
      read_as_wide_string(col, ind_ptr)
    else
      read_as_char_string(col, ind_ptr)
    end
  end

  private def read_as_char_string(col : Int32, ind_ptr : Pointer(Int64))
    # First call to get the length
    dummy = Bytes.new(1)
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_CHAR, dummy.to_unsafe, 0, ind_ptr)

    # Handle drivers that don't support length queries properly
    if !ODBC.success?(ret) && ret != LibODBC::SQL_SUCCESS_WITH_INFO
      # Try with a reasonable buffer size
      return read_string_with_buffer(col, 8192, LibODBC::SQL_C_CHAR, ind_ptr)
    end

    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
    return "" if ind_ptr.value == 0

    slen = ind_ptr.value
    # Add safety margin for null terminator and driver quirks
    buffer_size = slen + 10
    sbuf = Bytes.new(buffer_size)

    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_CHAR, sbuf.to_unsafe, buffer_size, ind_ptr)
    if !ODBC.success?(ret)
      # Fallback with different buffer size
      return read_string_with_buffer(col, 8192, LibODBC::SQL_C_CHAR, ind_ptr)
    end

    check ret
    actual_len = [slen, sbuf.size - 1].min
    String.new(sbuf[...actual_len])
  end

  private def read_as_wide_string(col : Int32, ind_ptr : Pointer(Int64))
    # First call to get the length
    dummy = Bytes.new(2)
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, dummy.to_unsafe, 0, ind_ptr)

    if !ODBC.success?(ret) && ret != LibODBC::SQL_SUCCESS_WITH_INFO
      # Try with a reasonable buffer size
      return read_wide_string_with_buffer(col, 4096, ind_ptr)
    end

    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
    return "" if ind_ptr.value == 0

    slen = (ind_ptr.value / 2).to_i
    buffer_size = slen + 10
    sbuf = Slice(UInt16).new(buffer_size)

    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, sbuf.to_unsafe, buffer_size * 2, ind_ptr)
    if !ODBC.success?(ret)
      return read_wide_string_with_buffer(col, 4096, ind_ptr)
    end

    check ret
    actual_len = [slen, sbuf.size - 1].min
    String.from_utf16(sbuf[...actual_len])
  end

  private def read_string_with_buffer(col : Int32, buffer_size : Int32, c_type : Int32, ind_ptr : Pointer(Int64))
    sbuf = Bytes.new(buffer_size)
    ret = LibODBC.sql_get_data(@stmt_handle, col, c_type, sbuf.to_unsafe, buffer_size, ind_ptr)
    return nil unless ODBC.success?(ret)
    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA

    # Find actual string length (null-terminated)
    actual_len = 0
    sbuf.each_with_index do |byte, i|
      if byte == 0
        actual_len = i
        break
      end
      actual_len = i + 1
    end

    String.new(sbuf[...actual_len])
  end

  private def read_wide_string_with_buffer(col : Int32, buffer_size : Int32, ind_ptr : Pointer(Int64))
    sbuf = Slice(UInt16).new(buffer_size)
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, sbuf.to_unsafe, buffer_size * 2, ind_ptr)
    return nil unless ODBC.success?(ret)
    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA

    # Find actual string length (null-terminated)
    actual_len = 0
    sbuf.each_with_index do |char, i|
      if char == 0
        actual_len = i
        break
      end
      actual_len = i + 1
    end

    String.from_utf16(sbuf[...actual_len])
  end

  private def read_as_string_fallback(col : Int32, ind_ptr : Pointer(Int64))
    # Try wide string first, then regular string
    result = read_wide_string_with_buffer(col, 4096, ind_ptr)
    return result unless result.nil?
    read_string_with_buffer(col, 8192, LibODBC::SQL_C_CHAR, ind_ptr)
  end

  private def read_as_binary(col : Int32, ind_ptr : Pointer(Int64))
    dummy = Bytes.new(1)
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BINARY, dummy.to_unsafe, 0, ind_ptr)

    if !ODBC.success?(ret) && ret != LibODBC::SQL_SUCCESS_WITH_INFO
      return nil
    end

    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
    return Bytes.empty if ind_ptr.value == 0

    buffer_size = ind_ptr.value.to_i + 1
    sbuf = Bytes.new(buffer_size)
    check LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_BINARY, sbuf.to_unsafe, buffer_size, ind_ptr)
    sbuf[...ind_ptr.value]
  end

  private def read_as_datetime(col : Int32, col_type : Int64, ind_ptr : Pointer(Int64))
    case col_type
    when LibODBC::SQL_TYPE_DATE, LibODBC::SQL_DATE
      read_as_date(col, ind_ptr)
    when LibODBC::SQL_TYPE_TIME, LibODBC::SQL_TIME
      read_as_time(col, ind_ptr)
    when LibODBC::SQL_TYPE_TIMESTAMP, LibODBC::SQL_TIMESTAMP
      read_as_timestamp(col, ind_ptr)
    else
      # Fallback: try timestamp first, then string parsing
      result = read_as_timestamp(col, ind_ptr)
      return result unless result.nil?
      read_datetime_as_string(col, ind_ptr)
    end
  end

  private def read_as_date(col : Int32, ind_ptr : Pointer(Int64))
    dt = uninitialized LibODBC::Date
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_DATE, pointerof(dt), sizeof(typeof(dt)), ind_ptr)
    if !ODBC.success?(ret)
      return read_datetime_as_string(col, ind_ptr)
    end
    check ret
    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
    Time.local(year: dt.year.to_i, month: dt.month.to_i, day: dt.day.to_i, location: Time::Location::UTC)
  end

  private def read_as_time(col : Int32, ind_ptr : Pointer(Int64))
    tm = uninitialized LibODBC::Time
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_TIME, pointerof(tm), sizeof(typeof(tm)), ind_ptr)
    if !ODBC.success?(ret)
      return read_datetime_as_string(col, ind_ptr)
    end
    check ret
    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA

    now = Time.utc
    Time.local(year: now.year.to_i, month: now.month.to_i, day: now.day.to_i,
      hour: tm.hour.to_i, minute: tm.minute.to_i, second: tm.second.to_i,
      location: Time::Location::UTC)
  end

  private def read_as_timestamp(col : Int32, ind_ptr : Pointer(Int64))
    tsv = uninitialized LibODBC::TimeStamp
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_TYPE_TIMESTAMP, pointerof(tsv), sizeof(typeof(tsv)), ind_ptr)
    if !ODBC.success?(ret)
      return read_datetime_as_string(col, ind_ptr)
    end
    check ret
    return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA

    Time.local(year: tsv.year.to_i, month: tsv.month.to_i, day: tsv.day.to_i,
      hour: tsv.hour.to_i, minute: tsv.minute.to_i, second: tsv.second.to_i,
      nanosecond: tsv.fraction.to_i, location: Time::Location::UTC)
  end

  private def read_datetime_as_string(col : Int32, ind_ptr : Pointer(Int64))
    str_val = read_as_string_fallback(col, ind_ptr)
    return nil if str_val.nil?

    # Try to parse common datetime formats
    begin
      Time.parse(str_val, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
    rescue Time::Format::Error
      begin
        Time.parse(str_val, "%Y-%m-%d", Time::Location::UTC)
      rescue Time::Format::Error
        begin
          Time.parse(str_val, "%H:%M:%S", Time::Location::UTC)
        rescue Time::Format::Error
          nil
        end
      end
    end
  end

  private def read_as_guid(col : Int32, ind_ptr : Pointer(Int64))
    # Try to read as wide string first
    slen = 36
    sbuf = Slice(UInt16).new(slen + 1)
    ret = LibODBC.sql_get_data(@stmt_handle, col, LibODBC::SQL_C_WCHAR, sbuf.to_unsafe, (slen + 1)*2, ind_ptr)

    if ODBC.success?(ret)
      return nil if ind_ptr.value == LibODBC::SQL_NULL_DATA
      return String.from_utf16(sbuf[...slen])
    end

    # Fallback to regular string
    read_as_string_fallback(col, ind_ptr)
  end

  def read(t : Int32.class) : Int32
    val = read
    case val
    when Int32
      val
    when Int64
      val.to_i32
    when String
      begin
        val.to_i32
      rescue ArgumentError
        raise DB::ColumnTypeMismatchError.new(context: "#{self.class}#read", column_index: @column_index - 2, column_name: column_name(@column_index - 2), column_type: val.class.to_s, expected_type: t.to_s)
      end
    when Float64
      val.to_i32
    else
      raise DB::ColumnTypeMismatchError.new(context: "#{self.class}#read", column_index: @column_index - 2, column_name: column_name(@column_index - 2), column_type: val.class.to_s, expected_type: t.to_s)
    end
  end

  def read(type : Int32?.class) : Int32?
    val = read
    case val
    when Int32
      val
    when Int64
      val.to_i32
    when String
      val.to_i32?
    when Float64
      val.to_i32
    when Nil
      nil
    else
      read(Int64?).try &.to_i32
    end
  end

  def read(t : Int64.class) : Int64
    val = read
    case val
    when Int64
      val
    when Int32
      val.to_i64
    when String
      val.to_i64
    when Float64
      val.to_i64
    else
      0_i64
    end
  end

  def read(type : Int64?.class) : Int64?
    val = read
    case val
    when Int64
      val
    when Int32
      val.to_i64
    when String
      val.to_i64?
    when Float64
      val.to_i64
    when Nil
      nil
    else
      nil
    end
  end

  def read(t : Float32.class) : Float32
    val = read
    case val
    when Float32
      val
    when Float64
      val.to_f32
    when String
      val.to_f32
    when Int64, Int32
      val.to_f32
    else
      read(Float64).to_f32
    end
  end

  def read(type : Float32?.class) : Float32?
    val = read
    case val
    when Float32
      val
    when Float64
      val.to_f32
    when String
      val.to_f32?
    when Int64, Int32
      val.to_f32
    when Nil
      nil
    else
      read(Float64?).try &.to_f32
    end
  end

  def read(t : Float64.class) : Float64
    val = read
    case val
    when Float64
      val
    when Float32
      val.to_f64
    when String
      val.to_f64
    when Int64, Int32
      val.to_f64
    else
      0.0
    end
  end

  def read(type : Float64?.class) : Float64?
    val = read
    case val
    when Float64
      val
    when Float32
      val.to_f64
    when String
      val.to_f64?
    when Int64, Int32
      val.to_f64
    when Nil
      nil
    else
      nil
    end
  end

  def read(t : Bool.class) : Bool
    val = read
    case val
    when Bool
      val
    when Int64
      val != 0
    when Int32
      val != 0
    when String
      val.downcase.in?("true", "1", "yes", "on")
    else
      false
    end
  end

  def read(type : Bool?.class) : Bool?
    val = read
    case val
    when Bool
      val
    when Int64
      val != 0
    when Int32
      val != 0
    when String
      val.downcase.in?("true", "1", "yes", "on")
    when Nil
      nil
    else
      false
    end
  end

  def read(t : String.class) : String
    val = read
    case val
    when String
      val
    else
      raise DB::ColumnTypeMismatchError.new(context: "#{self.class}#read", column_index: @column_index - 2, column_name: column_name(@column_index - 2), column_type: val.class.to_s, expected_type: t.to_s)
    end
  end

  def read(type : String?.class) : String?
    val = read
    case val
    when String
      val
    when Int64, Int32, Float64, Float32
      val.to_s
    when Bool
      val.to_s
    when Time
      val.to_s
    when Bytes
      String.new(val)
    when Nil
      nil
    else
      nil
    end
  end

  def read(t : Time.class) : Time
    val = read
    case val
    when Time
      val
    when String
      Time.parse(val, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
    else
      Time.utc
    end
  end

  def read(type : Time?.class) : Time?
    val = read
    case val
    when Time
      val
    when String
      begin
        Time.parse(val, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
      rescue Time::Format::Error
        nil
      end
    when Nil
      nil
    else
      nil
    end
  end

  def read(t : Bytes.class) : Bytes
    val = read
    case val
    when Bytes
      val
    when String
      val.to_slice
    else
      Bytes.empty
    end
  end

  def read(type : Bytes?.class) : Bytes?
    val = read
    case val
    when Bytes
      val
    when String
      val.to_slice
    when Nil
      nil
    else
      nil
    end
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
