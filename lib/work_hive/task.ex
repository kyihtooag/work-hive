defmodule WorkHive.Task do
  @moduledoc """
  The `WorkHive.Task` module defines the structure and behavior of tasks within the WorkHive application.

  A task represents a unit of work that needs to be executed. It has a `name`, a `command` to execute,
  and a list of `requires` that specify dependencies on other tasks.

  ## Task Structure
  A task is represented as a struct with the following fields:
  - `name`: A string representing the unique name of the task.
  - `command`: A string representing the command to execute for this task.
  - `requires`: A list of strings representing the names of tasks that this task depends on. Default is an empty list.

  ## Examples
      iex> task = WorkHive.Task.from_map(%{"name" => "task1", "command" => "echo hello", "requires" => ["task2"]})
      iex> task.name
      "task1"
      iex> task.command
      "echo hello"
      iex> task.requires
      ["task2"]
  """

  alias WorkHiveWeb.Errors.InvalidJsonError
  alias WorkHiveWeb.Errors.CircularDependencyError

  defstruct name: "",
            command: "",
            requires: []

  @type t :: %__MODULE__{
          name: String.t(),
          command: String.t(),
          requires: list(String.t())
        }

  @doc """
  Creates a `WorkHive.Task` struct from a map.

  The map must contain at least the `name` and `command` keys. The `requires` key is optional
  and defaults to an empty list if not provided.
  The function will raise an `InvalidJsonError` if the map is missing the `name` or `command` keys.

  ## Parameters
  - `task`(Map) : A map containing the task details. It must have the keys `name` and `command`.

  ## Returns
  - A `WorkHive.Task` struct.

  ## Raises
  - `InvalidJsonError`: If the map is missing the `name` or `command` keys.

  ## Examples
      iex> WorkHive.Task.from_map(%{"name" => "task1", "command" => "echo hello"})
      %WorkHive.Task{name: "task1", command: "echo hello", requires: []}

      iex> WorkHive.Task.from_map(%{"name" => "task1", "command" => "echo hello", "requires" => ["task2"]})
      %WorkHive.Task{name: "task1", command: "echo hello", requires: ["task2"]}

      iex> WorkHive.Task.from_map(%{"name" => "task1"})
      ** (InvalidJsonError) Invalid task format: A task must have a name and a command. %{"name" => "task1"}.
  """
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

  @doc """
  Sorts a list of tasks based on their dependencies order.

  Tasks without requires(dependencies) are executed first.
  Tasks with dependencies are only executed after all the tasks from the requires(dependencies) are executed.
  The function will raise a `CircularDependencyError` if a circular dependency is detected among the tasks.

  ## Parameters
  - `tasks`: A list of `WorkHive.Task` structs.

  ## Returns
  - A list of `WorkHive.Task` structs sorted in the correct execution order.

  ## Raises
  - `CircularDependencyError`: If a circular dependency is detected among the tasks.

  ## Examples
      iex> task1 = %WorkHive.Task{name: "task1", command: "echo hello", requires: []}
      iex> task2 = %WorkHive.Task{name: "task2", command: "echo world", requires: ["task1"]}
      iex> WorkHive.Task.sort_tasks_order([task1, task2])
      [%WorkHive.Task{name: "task1", command: "echo hello", requires: []}, %WorkHive.Task{name: "task2", command: "echo world", requires: ["task1"]}]

      iex> task1 = %WorkHive.Task{name: "task1", command: "echo hello", requires: ["task2"]}
      iex> task2 = %WorkHive.Task{name: "task2", command: "echo world", requires: ["task1"]}
      iex> WorkHive.Task.sort_tasks_order([task1, task2])
      ** (CircularDependencyError) Circular dependency detected: between "task1" and "task2".
  """
  @spec sort_tasks_order(list(__MODULE__.t())) :: list(__MODULE__.t())
  def sort_tasks_order(tasks), do: resolve_tasks(tasks)

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

      task.requires == [] ->
        sorted_tasks_list ++ [task]

      !is_nil(parent_task_name) and parent_task_name in task.requires ->
        raise CircularDependencyError,
          message:
            "Circular dependency detected: between #{inspect(parent_task_name)} and #{inspect(task.name)}."

      true ->
        resolved_tasks_list =
          resolve_required_tasks(tasks_list, task.requires, sorted_tasks_list, task.name)

        resolved_tasks_list ++ [task]
    end
  end

  defp resolve_required_tasks(tasks_list, requires, sorted_tasks_list, task_name) do
    Enum.reduce(requires, sorted_tasks_list, fn required_task_name, acc ->
      required_task = Enum.find(tasks_list, &(&1.name == required_task_name))
      resolve_dependencies(tasks_list, required_task, acc, task_name)
    end)
  end
end
