defmodule WorkHiveWeb.Errors do
  @moduledoc """
  The `WorkHiveWeb.Errors` module defines custom exceptions used in the WorkHive application.
  Each exception includes a default message and an HTTP status code that can be used in API responses.
  """
  defmodule InvalidJsonError do
    @moduledoc """
    Exception raised when invalid JSON is encountered.
    """
    defexception message: "Invalid JSON format", plug_status: 400
  end

  defmodule CircularDependencyError do
    @moduledoc """
    Exception raised when a circular dependency is detected.
    """
    defexception message: "Circular dependency detected", plug_status: 400
  end
end
