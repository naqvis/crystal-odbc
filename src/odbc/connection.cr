class ODBC::Connection < DB::Connection
  protected getter con_handle

  def initialize(ctx : DB::ConnectionContext)
    super
    @env_handle = uninitialized LibODBC::Sqlhandle
    @con_handle = uninitialized LibODBC::Sqlhandle

    init_env
    init_con(ctx.uri)
  end

  def build_prepared_statement(query) : ODBC::Statement
    Statement.new(self, query)
  end

  def build_unprepared_statement(query) : ODBC::UnPreparedStatement
    UnPreparedStatement.new(self, query)
  end

  # :nodoc:
  def perform_begin_transaction
    # Check for transaction support
    txn_cap = 0_i16
    check LibODBC.sql_get_info_w(con_handle, LibODBC::SQL_TXN_CAPABLE, pointerof(txn_cap), 2, nil)

    raise Error.new("transactions are not supported by this ODBC driver") if txn_cap == LibODBC::SQL_TC_NONE

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

  private def init_con(uri)
    raise Error.new("driver has been closed") if @env_handle.nil?
    dsn = URI.decode_www_form((uri.host || "") + uri.path)

    # Allocate the connection handle
    env_check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_DBC, @env_handle, pointerof(@con_handle))

    # Perform the driver connect
    name = ODBC.to_c(dsn)
    check LibODBC.sql_driver_connect(con_handle, nil, name.to_unsafe, name.size, nil, 0, nil, LibODBC::SQL_DRIVER_NOPROMPT)
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
end

module ODBC
  def self.to_c(str : String)
    size = str.bytesize
    slice = Bytes.new(size + 1) do |i|
      if i == size
        0_u8
      else
        # str.unsafe_byte_at(i).to_u8
        str.to_unsafe[i].to_u8
      end
    end
    slice[0, size]
  end
end
