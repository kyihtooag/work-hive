defmodule WorkHiveWeb.TaskController do
  use WorkHiveWeb, :controller

  alias WorkHive.Task

  def sort(conn, %{"tasks" => tasks} = params) do
    sorted_tasks =
      tasks
      |> Enum.map(&Task.from_map/1)
      |> Task.sort_tasks_order()

    case params["format"] do
      "bash" ->
        command_scripts = generate_bash_script(sorted_tasks)
        text(conn, command_scripts)

      _ ->
        render(conn, :sort, sorted_tasks: sorted_tasks)
    end
  end

  defp generate_bash_script(sorted_tasks) do
    header = "#!/usr/bin/env bash\n\n"

    Enum.reduce(sorted_tasks, header, fn task, acc ->
      acc <> task.command <> "\n"
    end)
  end
end
