defmodule WorkHiveWeb.TaskJSON do
  def sort(%{sorted_tasks: sorted_tasks}) do
    %{data: for(task <- sorted_tasks, do: data(task))}
  end

  defp data(task) do
    %{
      name: task.name,
      command: task.command
    }
  end
end
