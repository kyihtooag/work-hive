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
  def sort_tasks_order([]), do: []

  def sort_tasks_order(tasks) do
    # Create a map of tasks for efficient lookup
    tasks_map = Enum.into(tasks, %{}, fn task -> {task.name, task} end)
    do_sort_tasks_order(tasks, tasks_map)
  end

  # Resolve the tasks based on their dependencies
  # If the task is already sorted, skip it
  # If the task has dependencies, resolve them first
  # tasks - List of tasks to resolve
  # tasks_map - Map of tasks for efficient lookup
  # processing_stack - List of tasks being processed to detect circular dependencies
  # sorted_tasks_list - List of tasks that are already sorted
  defp do_sort_tasks_order(tasks, tasks_map, processing_stack \\ [], sorted_tasks_list \\ []) do
    Enum.reduce(
      tasks,
      {
        tasks_map,
        processing_stack,
        sorted_tasks_list
      },
      fn task, {tasks_map, processing_stack, sorted_tasks_list} ->
        # Skip tasks that are already sorted
        if task in sorted_tasks_list do
          {tasks_map, processing_stack, sorted_tasks_list}
        else
          resolve_tasks(tasks, tasks_map, task, processing_stack, sorted_tasks_list)
        end
      end
    )
    # Extract the sorted list after all tasks are resolved
    |> elem(2)
  end

  # Resolve the unsorted tasks
  defp resolve_tasks(
         tasks_list,
         tasks_map,
         task,
         processing_stack,
         sorted_tasks_list
       ) do
    cond do
      # If the task has already been sorted, skip it
      task in sorted_tasks_list ->
        {tasks_map, processing_stack, sorted_tasks_list}

      # If the task has no dependencies, add it to the sorted list
      task.requires == [] ->
        {tasks_map, processing_stack, sorted_tasks_list ++ [task]}

      # If the task is already in the processing stack,
      # Raise a circular dependency error with the name of the tasks in the stack
      task.name in processing_stack ->
        raise CircularDependencyError,
          message: "Circular dependency detected: between #{Enum.join(processing_stack, ", ")}."

      # If the task has dependencies, resolve them first
      true ->
        # Add the current task to the processing stack to detect circular dependencies
        processing_stack = processing_stack ++ [task.name]

        {tasks_map, processing_stack, resolved_tasks_list} =
          resolve_task_dependencies(
            tasks_list,
            tasks_map,
            task.requires,
            processing_stack,
            sorted_tasks_list
          )

        # Remove the current task from the processing stack since it is resolved
        {tasks_map, List.delete(processing_stack, task.name), resolved_tasks_list ++ [task]}
    end
  end

  # Resolve the task's required dependencies tasks
  defp resolve_task_dependencies(
         tasks_list,
         tasks_map,
         requires,
         processing_stack,
         sorted_tasks_list
       ) do
    Enum.reduce(
      requires,
      {tasks_map, processing_stack, sorted_tasks_list},
      fn required_task_name, {tasks_map, processing_stack, sorted_tasks_list} ->
        # Get the required task from the task map
        required_task = Map.get(tasks_map, required_task_name)

        resolve_tasks(
          tasks_list,
          tasks_map,
          required_task,
          processing_stack,
          sorted_tasks_list
        )
      end
    )
  end
end
