defmodule WorkHiveWeb.Errors do
  defmodule InvalidJsonError do
    defexception message: "Invalid JSON format", plug_status: 400
  end

  defmodule CircularDependencyError do
    defexception message: "Circular dependency detected", plug_status: 400
  end
end
