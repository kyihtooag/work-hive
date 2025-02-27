defmodule WorkHiveWeb.Router do
  use WorkHiveWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WorkHiveWeb do
    pipe_through :api

    post "/tasks", TaskController, :sort
  end
end
