defmodule WorkHiveWeb.TaskJSON do
  def index(%{tasks: tasks}) do
    %{data: for(task <- tasks, do: data(task))}
  end

  defp data(task) do
    %{
      name: task.name,
      command: task.command
    }
  end
end
