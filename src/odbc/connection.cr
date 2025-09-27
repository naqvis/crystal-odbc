class ODBC::Connection < DB::Connection
  protected getter con_handle
  private getter driver_info : DriverInfo?

  record Options, dsn : String do
    def self.from_uri(uri : URI)
      Options.new(URI.decode_www_form((uri.host || "") + uri.path))
    end
  end

  # Driver capability information
  record DriverInfo,
    name : String,
    version : String,
    supports_transactions : Bool,
    max_identifier_length : Int32

  # def initialize(ctx : DB::ConnectionContext)
  def initialize(options : ::DB::Connection::Options, odbc_options : Options)
    super(options)
    @env_handle = uninitialized LibODBC::Sqlhandle
    @con_handle = uninitialized LibODBC::Sqlhandle

    init_env
    init_con(odbc_options.dsn)
    @driver_info = detect_driver_capabilities
  end

  def build_prepared_statement(query) : ODBC::Statement
    Statement.new(self, query)
  end

  def build_unprepared_statement(query) : ODBC::UnPreparedStatement
    UnPreparedStatement.new(self, query)
  end

  # :nodoc:
  def perform_begin_transaction
    # Check for transaction support using cached driver info
    unless supports_transactions?
      raise Error.new("transactions are not supported by this ODBC driver (#{driver_name})")
    end

    # Turn autocommit off
    auto_commit(false)
  end

  # :nodoc:
  def perform_commit_transaction
    # Commit the transaction
    check LibODBC.sql_end_tran(LibODBC::SQL_HANDLE_DBC, con_handle, LibODBC::SQL_COMMIT)

    # Turn autocommit back on
    auto_commit(true)
  end

  # :nodoc:
  def perform_rollback_transaction
    # Rollback the transaction
    check LibODBC.sql_end_tran(LibODBC::SQL_HANDLE_DBC, con_handle, LibODBC::SQL_ROLLBACK)

    # Turn autocommit back on
    auto_commit(true)
  end

  # Check if the connection is still alive and functional
  def connection_alive? : Bool
    return false if con_handle.null?

    # Try to get connection info as a simple connectivity test
    ret = LibODBC.sql_get_info_w(con_handle, LibODBC::SQL_DRIVER_NAME, nil, 0, nil)
    ODBC.success?(ret) || ret == LibODBC::SQL_SUCCESS_WITH_INFO
  rescue
    false
  end

  def do_close
    super
    return if con_handle.null?
    # Disconnect the connection
    ODBC.check LibODBC.sql_disconnect(con_handle) do
      err = ODBC.get_errors(ErrorType::DBC, con_handle)
      LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_DBC, con_handle)
      raise Error.from_status(err)
    end

    # Free the connection handle
    check LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_DBC, con_handle)

    ODBC.check LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_ENV, @env_handle), "failed to free environment handler"

    @con_handle = LibODBC::Sqlhandle.null
    @env_handle = LibODBC::Sqlhandle.null
  end

  private def init_env
    # Allocate the environment handle for the driver
    ODBC.check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_ENV, nil, pointerof(@env_handle)), "failed to allocate environment handle"

    # Set the environment handle to use ODBCv3
    val = LibODBC::SQL_OV_ODBC3_80.to_u32.unsafe_as(Pointer(Void))

    ODBC.check LibODBC.sql_set_env_attr(@env_handle, LibODBC::SQL_ATTR_ODBC_VERSION, val, 0) do
      err = ODBC.get_errors(ErrorType::ENV, @env_handle)
      LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_ENV, @env_handle)
      raise Error.from_status(err)
    end
  end

  private def init_con(dsn)
    raise Error.new("driver has been closed") if @env_handle.nil?

    # Allocate the connection handle
    env_check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_DBC, @env_handle, pointerof(@con_handle))

    # Perform the driver connect
    check LibODBC.sql_driver_connect(con_handle, nil, dsn, dsn.bytesize, nil, 0, nil, LibODBC::SQL_DRIVER_NOPROMPT)
  end

  private def auto_commit(flag : Bool)
    val = flag ? LibODBC::SQL_AUTOCOMMIT_ON : LibODBC::SQL_AUTOCOMMIT_OFF
    check LibODBC.sql_set_connect_attr_w(con_handle, LibODBC::SQL_ATTR_AUTOCOMMIT, val, LibODBC::SQL_IS_UINTEGER)
  end

  private def check(code)
    ODBC.check code do
      err = ODBC.get_errors(ErrorType::DBC, con_handle)
      raise Error.from_status(err)
    end
    code
  end

  private def env_check(code)
    ODBC.check code do
      err = ODBC.get_errors(ErrorType::ENV, @env_handle)
      raise Error.from_status(err)
    end
    code
  end

  private def detect_driver_capabilities : DriverInfo
    # Get driver name
    driver_name = get_info_string(LibODBC::SQL_DRIVER_NAME) || "Unknown"

    # Get driver version
    driver_version = get_info_string(LibODBC::SQL_DRIVER_VER) || "Unknown"

    # Check transaction support
    txn_cap = get_info_int16(LibODBC::SQL_TXN_CAPABLE) || LibODBC::SQL_TC_NONE
    supports_transactions = txn_cap != LibODBC::SQL_TC_NONE

    # Get maximum identifier length
    max_id_len = get_info_int16(LibODBC::SQL_MAX_IDENTIFIER_LEN) || 128

    DriverInfo.new(
      name: driver_name,
      version: driver_version,
      supports_transactions: supports_transactions,
      max_identifier_length: max_id_len.to_i32
    )
  end

  private def get_info_string(info_type : Int32) : String?
    buffer = Slice(UInt16).new(256)
    ret = LibODBC.sql_get_info_w(con_handle, info_type, buffer.to_unsafe, buffer.size * 2, out actual_len)
    return nil unless ODBC.success?(ret)

    str_len = (actual_len / 2).to_i
    String.from_utf16(buffer[...str_len])
  rescue
    nil
  end

  private def get_info_int16(info_type : Int32) : Int16?
    value = uninitialized Int16
    ret = LibODBC.sql_get_info_w(con_handle, info_type, pointerof(value), 2, nil)
    return nil unless ODBC.success?(ret)
    value
  rescue
    nil
  end

  # Public method to check if driver supports specific features
  def supports_transactions? : Bool
    @driver_info.try(&.supports_transactions) || false
  end

  def driver_name : String
    @driver_info.try(&.name) || "Unknown"
  end

  def max_identifier_length : Int32
    @driver_info.try(&.max_identifier_length) || 128
  end
end
