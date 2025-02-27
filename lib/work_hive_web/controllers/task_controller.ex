defmodule WorkHiveWeb.TaskController do
  use WorkHiveWeb, :controller

  alias WorkHive.Task

  def sort(conn, %{"tasks" => tasks}) do
    sorted_tasks =
      tasks
      |> Enum.map(&Task.from_map/1)
      |> Task.sort_tasks_order()

    render(conn, :sort, sorted_tasks: sorted_tasks)
  end
end
