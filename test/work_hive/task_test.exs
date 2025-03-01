defmodule WorkHive.TaskTest do
  use ExUnit.Case, async: true

  alias WorkHive.Task
  alias WorkHiveWeb.Errors.InvalidJsonError
  alias WorkHiveWeb.Errors.CircularDependencyError

  describe "from_map/1" do
    test "creates a task from a valid map" do
      task_map = %{"name" => "task1", "command" => "echo hello", "requires" => ["task2"]}
      task = Task.from_map(task_map)

      assert task.name == "task1"
      assert task.command == "echo hello"
      assert task.requires == ["task2"]
    end

    test "creates a task with default requires when not provided" do
      task_map = %{"name" => "task1", "command" => "echo hello"}
      task = Task.from_map(task_map)

      assert task.name == "task1"
      assert task.command == "echo hello"
      assert task.requires == []
    end

    test "raises InvalidJsonError when name or command is missing" do
      invalid_task_map = %{"name" => "task1"}

      assert_raise InvalidJsonError, fn ->
        Task.from_map(invalid_task_map)
      end

      invalid_task_map_2 = %{"command" => "echo hello"}

      assert_raise InvalidJsonError, fn ->
        Task.from_map(invalid_task_map_2)
      end
    end
  end

  describe "sort_tasks_order/1" do
    test "empty list of tasks returns an empty list" do
      tasks = []
      sorted_tasks = Task.sort_tasks_order(tasks)

      assert sorted_tasks == []
    end

    test "sorts tasks correctly when there are no dependencies" do
      task1 = %Task{name: "task1", command: "echo hello", requires: []}
      task2 = %Task{name: "task2", command: "echo world", requires: []}

      tasks = [task1, task2]
      sorted_tasks = Task.sort_tasks_order(tasks)

      assert sorted_tasks == [task1, task2]
    end

    test "sorts tasks correctly with dependencies" do
      task1 = %Task{name: "task1", command: "echo hello", requires: ["task2"]}
      task2 = %Task{name: "task2", command: "echo world", requires: []}

      tasks = [task1, task2]
      sorted_tasks = Task.sort_tasks_order(tasks)

      assert sorted_tasks == [task2, task1]
    end

    test "raises CircularDependencyError when a circular dependency is detected" do
      task1 = %Task{name: "task1", command: "echo hello task-1", requires: ["task2"]}
      task2 = %Task{name: "task2", command: "echo hello task-2", requires: ["task3"]}
      task3 = %Task{name: "task3", command: "echo hello task-3", requires: ["task1"]}

      tasks = [task1, task2, task3]

      assert_raise CircularDependencyError, fn ->
        Task.sort_tasks_order(tasks)
      end
    end

    test "handles complex dependency chains correctly" do
      task1 = %Task{name: "task1", command: "echo hello", requires: ["task2", "task3"]}
      task2 = %Task{name: "task2", command: "echo world", requires: ["task3"]}
      task3 = %Task{name: "task3", command: "echo universe", requires: []}

      tasks = [task1, task2, task3]
      sorted_tasks = Task.sort_tasks_order(tasks)

      assert sorted_tasks == [task3, task2, task1]
    end
  end
end
