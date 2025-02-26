defmodule WorkHiveWeb.TaskController do
  use WorkHiveWeb, :controller

  def index(conn, _params) do
    dummy_tasks_list = [
      %{
        name: "Task 1",
        command: "echo 'Task 1'"
      },
      %{
        name: "Task 2",
        command: "echo 'Task 2'"
      }
    ]

    render(conn, :index, tasks: dummy_tasks_list)
  end
end
