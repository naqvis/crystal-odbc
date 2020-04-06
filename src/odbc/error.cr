module ODBC
  # Exception thrown on invalid ODBC operations.
  class Error < Exception
    def self.from_status(errors : Array(StatusRecord))
      return new("Empty errors parameter") unless errors.size > 0
      msg = String.build do |sb|
        errors.each do |err|
          sb << err.to_s << "\n"
        end
      end
      new(msg)
    end
  end

  # :nodoc:
  record StatusRecord, state : String, native_error : Int32, message : String do
    def to_s
      "{#{state}} #{message}"
    end
  end

  enum ErrorType
    ENV
    DBC
    STMT
  end

  # :nodoc:
  def self.get_errors(htype : ErrorType, handle)
    _type = case htype
            when .env?  then LibODBC::SQL_HANDLE_ENV
            when .dbc?  then LibODBC::SQL_HANDLE_DBC
            when .stmt? then LibODBC::SQL_HANDLE_STMT
            else             raise Error.new("Uknown odbc handle type")
            end

    # Get the number of diagnostic records
    rec_count = 0
    ret = LibODBC.sql_get_diag_field_w(_type, handle, 0, LibODBC::SQL_DIAG_NUMBER, pointerof(rec_count), 4, nil)
    check ret, "failed to retrieve diagnostic header information"

    # Query each of the diagnostic records
    status_recs = Array(StatusRecord).new(rec_count)
    1.upto(rec_count) do |i|
      # Find the needed size for the message buffer
      ret = LibODBC.sql_get_diag_rec_w(_type, handle, i, nil, nil, nil, 0, out msg_len)

      next unless success?(ret)

      # Get the diagnostic record values
      state = Slice(UInt16).new(6)
      state_ptr = state.to_unsafe
      msg_buf = Slice(UInt16).new(msg_len + 1)
      buf_ptr = msg_buf.to_unsafe

      ret = LibODBC.sql_get_diag_rec_w(_type, handle, i, state_ptr, out native_error, buf_ptr, msg_len + 1, nil)

      next unless success?(ret)

      status_recs << StatusRecord.new(String.from_utf16(state[...5]), native_error, String.from_utf16(msg_buf[...msg_len]))
    end
    status_recs
  end

  # :nodoc:
  def self.check(code, msg)
    raise Error.new(msg) unless success?(code)
  end

  # :nodoc:
  def self.check(code, &block)
    yield unless success?(code)
  end

  # :nodoc:
  def self.success?(code)
    code == LibODBC::SQL_SUCCESS || code == LibODBC::SQL_SUCCESS_WITH_INFO
  end
end
