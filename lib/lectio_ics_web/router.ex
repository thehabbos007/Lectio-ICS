defmodule LectioIcsWeb.Router do
  use LectioIcsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LectioIcsWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    scope "/api" do
      pipe_through :api
      get "/:school_id/:student_id/:weeks", PageController, :lectio
    end
    
  end

  # Other scopes may use custom stacks.
  # scope "/api", LectioIcsWeb do
  #   pipe_through :api
  # end
end
