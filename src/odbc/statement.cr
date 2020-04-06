class ODBC::Statement < DB::Statement
  @con_handle : LibODBC::Sqlhandle

  def initialize(connection, sql)
    super(connection)
    @con_handle = connection.as(Connection).con_handle
    @stmt_handle = uninitialized LibODBC::Sqlhandle
    @num_input = 0
    @params = Array(ParamType).new
    prepare(sql)
  end

  protected def perform_query(args : Enumerable) : DB::ResultSet
    execute(args)
    ResultSet.new(self, @stmt_handle)
  end

  protected def perform_exec(args : Enumerable) : DB::ExecResult
    execute(args)

    # Get the number of rows affected
    check LibODBC.sql_row_count(@stmt_handle, out rows_affected)

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

  private def prepare(sql)
    # Allocate the statement handle
    check LibODBC.sql_alloc_handle(LibODBC::SQL_HANDLE_STMT, @con_handle, pointerof(@stmt_handle))

    query = ODBC.to_c(sql)
    # Prepare the statement
    ODBC.check LibODBC.sql_prepare(@stmt_handle, query.to_unsafe, LibODBC::SQL_NTS) do
      err = ODBC.get_errors(ErrorType::STMT, @stmt_handle)
      LibODBC.sql_free_handle(LibODBC::SQL_HANDLE_STMT, @stmt_handle)
      raise Error.from_status(err)
    end

    # Get the input count
    param_count = uninitialized Int16
    ret = LibODBC.sql_num_params(@stmt_handle, pointerof(param_count))
    @num_input = param_count.to_i if ODBC.success?(ret)
  end

  private def execute(args)
    bind(args)
    # Execute the statement
    ret = LibODBC.sql_execute(@stmt_handle)
    if !ODBC.success?(ret) && ret != LibODBC::SQL_NO_DATA
      err = ODBC.get_errors(ErrorType::STMT, @stmt_handle)
      raise Error.from_status(err)
    end
  end

  private def reset
    check LibODBC.sql_free_stmt(@stmt_handle, LibODBC::SQL_RESET_PARAMS)
    @params.clear
  end

  private def bind(args)
    params = args.to_a.flatten
    raise Error.new("Number of arguments (#{args.size}) provided doesn't match with input parameters count (#{@num_input}) ") unless params.size >= @num_input
    if @num_input > 0 && params.size > 0
      reset
      0.upto(@num_input - 1) do |index|
        bind_arg(index + 1, params[index])
      end
    end
  end

  private def bind_arg(index, value : Nil)
    ft, _, _, _ = param_type(index)
    ptype = ft.to_i16
    ptype = LibODBC::SQL_WCHAR if ptype == LibODBC::SQL_UNKNOWN_TYPE
    inp = LibODBC::SQL_NULL_DATA.to_i64

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_DEFAULT, ptype, 1, 0, nil, 0, pointerof(inp))
  end

  private def bind_arg(index, value : Bool)
    bval = Bytes.new(1)
    bval[0] = value ? 1_u8 : 0_u8
    inp = 1_i64
    p = Param(Slice(UInt8)).new(bval, inp)
    @params << p
    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_BIT, LibODBC::SQL_BIT, 0, 0, p.val.to_unsafe, 1, p.pcb_value)
  end

  private def bind_arg(index, value : Int32)
    bind_arg index, value.to_i64
  end

  private def bind_arg(index, value : Int64)
    pvt = Slice(Int64).new(1, value)
    inp = 8_i64
    p = Param(Slice(Int64)).new(pvt, inp)
    @params << p

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_SBIGINT, LibODBC::SQL_BIGINT, 8, 0, p.val.to_unsafe, 0, p.pcb_value)
  end

  private def bind_arg(index, value : Float32)
    bind_arg index, value.to_f64
  end

  private def bind_arg(index, value : Float64)
    pvt = Slice(Float64).new(1, value)

    inp = sizeof(Float64).to_i64
    p = Param(Slice(Float64)).new(pvt, inp)
    @params << p

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_DOUBLE, LibODBC::SQL_DOUBLE, 0, 0, p.val.to_unsafe, 0, p.pcb_value)
  end

  private def bind_arg(index, value : String)
    pvt = ODBC.to_c value
    len = pvt.size.to_u64

    p = Param(Slice(UInt8)).new(pvt, len.to_i64)
    @params << p

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_CHAR, LibODBC::SQL_VARCHAR, len, 0, p.val.to_unsafe, len, p.pcb_value)
  end

  private def bind_arg(index, value : Bytes)
    p = Param(Slice(UInt8)).new(value, value.size.to_i64)
    @params << p

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_BINARY, LibODBC::SQL_BINARY, p.size, 0, p.val.to_unsafe, p.size, p.pcb_value)
  end

  private def bind_arg(index, value : Time)
    tsv = LibODBC::TimeStamp.new
    tsv.year = value.year.to_i16
    tsv.month = value.month.to_i16
    tsv.day = value.day.to_i16
    tsv.hour = value.hour.to_i16
    tsv.minute = value.minute.to_i16
    tsv.second = value.second.to_i16
    tsv.fraction = value.nanosecond

    p = Param(LibODBC::TimeStamp).new(tsv, sizeof(LibODBC::TimeStamp).to_i64)
    @params << p

    check LibODBC.sql_bind_parameter(@stmt_handle, index.to_i16, LibODBC::SQL_PARAM_INPUT,
      LibODBC::SQL_C_TYPE_TIMESTAMP, LibODBC::SQL_TYPE_TIMESTAMP, 0, 0, p.val_ptr, p.size, p.pcb_value)
  end

  private def bind_arg(index, value)
    raise Error.new("#{self.class} does not support #{value.class} params")
  end

  private def param_type(index)
    size_ptr = uninitialized LibODBC::Sqlulen
    check LibODBC.sql_describe_param(@stmt_handle, index.to_i16, out data_type, pointerof(size_ptr), out dec_ptr, out null_ptr)

    {data_type.to_i, size_ptr.to_i, dec_ptr.to_i, null_ptr.to_i}
  end

  private def check(code)
    ODBC.check code do
      err = ODBC.get_errors(ErrorType::STMT, @stmt_handle)
      raise Error.from_status(err)
    end
    code
  end
end

module ODBC
  private alias ParamType = Param(Slice(UInt8)) | Param(Slice(UInt16)) | Param(Slice(Int64)) | Param(Slice(Float64)) | Param(LibODBC::TimeStamp)

  private class Param(T)
    getter val

    def initialize(@val : T, @pcb_value : LibODBC::Sqllen)
    end

    def size
      @pcb_value
    end

    def pcb_value
      pointerof(@pcb_value)
    end

    def val_ptr
      pointerof(@val)
    end
  end
end
