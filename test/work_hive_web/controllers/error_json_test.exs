defmodule WorkHiveWeb.ErrorJSONTest do
  use WorkHiveWeb.ConnCase, async: true

  alias WorkHiveWeb.Errors.InvalidJsonError
  alias WorkHiveWeb.Errors.CircularDependencyError

  test "renders 400 for InvalidJsonError" do
    assert WorkHiveWeb.ErrorJSON.render("400.json", %{reason: %InvalidJsonError{}}) == %{
             error: "Invalid JSON format"
           }
  end

  test "renders 400 for CircularDependencyError" do
    assert WorkHiveWeb.ErrorJSON.render("400.json", %{reason: %CircularDependencyError{}}) == %{
             error: "Circular dependency detected"
           }
  end

  test "renders 404" do
    assert WorkHiveWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert WorkHiveWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
