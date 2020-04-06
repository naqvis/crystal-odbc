class ODBC::UnPreparedStatement < DB::Statement
  protected getter stmt_handle
  @con_handle : LibODBC::Sqlhandle

  def initialize(connection, @sql : String)
    super(connection)
    @con_handle = connection.as(Connection).con_handle
    @stmt_handle = uninitialized LibODBC::Sqlhandle
    init
  end

  protected def perform_query(args : Enumerable) : DB::ResultSet
    execute(args)

    ResultSet.new(self, @stmt_handle)
  end

  protected def perform_exec(args : Enumerable) : DB::ExecResult
    execute(args)

    # Get the number of rows affected
    check LibODBC.sql_row_count(@stmt_handle, out rows_affected)

    # unprepared statements are not closed by framework, so let's close this statement by ourselves
    do_close

    # ODBC doesn't support last_insert_id so returning value of -1
    DB::ExecResult.new rows_affected, -1.to_i64
  end

  protected def do_close
    super
    return if @stmt_handle.null?
    # Free the statement handle
    check LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_STMT, @stmt_handle)

    @stmt_handle = LibODBC::Sqlhandle.null
  end

  private def init
    # Allocate the statement handle
    check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_STMT, @con_handle, pointerof(@stmt_handle))
  end

  private def execute(args)
    raise Error.new("#{self.class} does not support query execution with arguments") unless args.size == 0
    query = ODBC.to_c @sql
    # Execute the statement
    check LibODBC.sql_exec_direct(@stmt_handle, query.to_unsafe, LibODBC::SQL_NTS)
  end

  private def check(code)
    ODBC.check code do
      err = ODBC.get_errors(ErrorType::STMT, @stmt_handle)
      raise Error.from_status(err)
    end
    code
  end
end
