defmodule WorkHive.Task do
  alias WorkHiveWeb.Errors.InvalidJsonError
  alias WorkHiveWeb.Errors.CircularDependencyError

  defstruct name: "",
            command: "",
            requires: []

  @type t :: %__MODULE__{
          name: String.t(),
          command: String.t(),
          requires: List.t()
        }

  @spec from_map(map()) :: __MODULE__.t()
  def from_map(%{"name" => name, "command" => command} = task) do
    %__MODULE__{
      name: name,
      command: command,
      requires: Map.get(task, "requires", [])
    }
  end

  def from_map(error_task),
    do:
      raise(InvalidJsonError,
        message:
          "Invalid task format: A task must have a name and a command. #{inspect(error_task)}."
      )

  # sort by requires step, the task without requires step will be executed first
  def sort_tasks_order(tasks) do
    resolve_tasks(tasks)
  end

  defp resolve_tasks(tasks, sorted_tasks_list \\ []) do
    Enum.reduce(tasks, sorted_tasks_list, fn task, acc ->
      if task.name in acc do
        acc
      else
        resolve_dependencies(tasks, task, acc)
      end
    end)
  end

  defp resolve_dependencies(tasks_list, task, sorted_tasks_list, parent_task_name \\ nil) do
    cond do
      task in sorted_tasks_list ->
        sorted_tasks_list

      Map.get(task, :requires, []) == [] ->
        [task | sorted_tasks_list]

      !is_nil(parent_task_name) and parent_task_name in task.requires ->
        raise CircularDependencyError,
          message:
            "Circular dependency detected: between #{inspect(parent_task_name)} and #{inspect(task.name)}."

      true ->
        resolved_tasks_list =
          Enum.reduce(task.requires, sorted_tasks_list, fn required_task_name, acc ->
            required_task = Enum.find(tasks_list, fn task -> task.name == required_task_name end)
            resolve_dependencies(tasks_list, required_task, acc, task.name)
          end)

        resolved_tasks_list ++ [task]
    end
  end
end
