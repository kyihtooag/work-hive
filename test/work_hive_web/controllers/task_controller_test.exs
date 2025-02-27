defmodule WorkHiveWeb.TaskControllerTest do
  use WorkHiveWeb.ConnCase

  alias WorkHiveWeb.Errors.InvalidJsonError
  alias WorkHiveWeb.Errors.CircularDependencyError

  test "returns sorted tasks", %{conn: conn} do
    valid_tasks = [
      %{"name" => "task1", "command" => "command1", requires: ["task2"]},
      %{"name" => "task2", "command" => "command2"}
    ]

    conn = post(conn, ~p"/api/tasks", tasks: valid_tasks)

    assert json_response(conn, 200) == %{
             "data" => [
               %{"name" => "task2", "command" => "command2"},
               %{"name" => "task1", "command" => "command1"}
             ]
           }
  end

  test "returns sorted tasks and bash scripts as a text response if the 'format' param is set to 'bash'",
       %{conn: conn} do
    valid_tasks = [
      %{"name" => "task1", "command" => "command1", requires: ["task2"]},
      %{"name" => "task2", "command" => "command2"}
    ]

    conn = post(conn, ~p"/api/tasks?format=bash", tasks: valid_tasks)

    assert text_response(conn, 200) == "#!/usr/bin/env bash\n\ncommand2\ncommand1\n"
  end

  test "raise InvalidJsonError if the task format is not valid", %{conn: conn} do
    invalid_tasks = [
      %{"name" => "task1", "command" => "command1"},
      %{"name" => "task2"}
    ]

    assert_raise InvalidJsonError, fn ->
      post(conn, ~p"/api/tasks", tasks: invalid_tasks)
    end
  end

  test "raise CircularDependencyError if circular dependency detected between tasks", %{
    conn: conn
  } do
    circular_tasks = [
      %{"name" => "task1", "command" => "command1", requires: ["task2"]},
      %{"name" => "task2", "command" => "command2", requires: ["task1"]}
    ]

    assert_raise CircularDependencyError, fn ->
      post(conn, ~p"/api/tasks", tasks: circular_tasks)
    end
  end
end
