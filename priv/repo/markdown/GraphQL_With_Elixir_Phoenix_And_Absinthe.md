Elixir is a language that lends itself perfectly to creating graphql apis and the creators of [Absinthe](https://github.com/absinthe-graphql/absinthe) have written a great implementation of the graphql specification. We will create a very simple graphql api with queries, mutations and subscriptions. Then we will take it for a ride in graphiql. A graphql playground that lets you test out your api. I won't explain [what graphql is](https://graphql.org/), I'll just show you how to do it the Absinthe way.

We are going to create an app that tracks the status of workers at a call center. You can imagine you want to know who is signed in and if the are in a call or not. Our graphql api could be used to update a realtime dashboard.

First create a new Phoenix project:

```bash
mix phx.new employee_status --no-webpack --no-html
```

Then add these lines to your mix.exs:

```elixir
{:absinthe, "~> 1.4"},
{:absinthe_plug, "~> 1.4"},
{:absinthe_phoenix, "~> 2.0"},
{:poison, "~> 2.1.0"}
```

Then run:

```bash
mix deps.get
```

Now we have to generate the context for our app:

```bash
mix phx.gen.context Staff Employee employees name:string status:string
```

Very simple we just have employee names and their status. Lets get ecto setup:

```bash
mix ecto.setup
```

Now we will start working on our graphql schema so lets make a new file at lib/employee_status_web/schema.ex:

```elixir
defmodule EmployeeStatusWeb.Schema do
  use Absinthe.Schema

  alias EmployeeStatusWeb.EmployeeResolver

  object :employee do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :status, non_null(:string)
  end


  query do
    @desc "Get all employees"
    field :all_employees, non_null(list_of(non_null(:employee))) do
      resolve(&EmployeeResolver.all_employees/3)
    end
  end
end
```

We have our base object which is very similar to the ecto schema we generated before. We also have our first query. It is being resolved by the EmployeeResolver module. Lets fill that out next. Make a new file at lib/employee_status_web/resolvers/employee_resolver.ex:

```elixir
defmodule EmployeeStatusWeb.EmployeeResolver do
  alias EmployeeStatus.Staff

  def all_employees(_root, _args, _info) do
    {:ok, Staff.list_employees()}
  end

end
```

Ok, simple enough we are just using the CRUD operations we generated earlier. Speaking of CRUD lets just do them all the graphql way. Lets add some mutations to our schema for creating, updating and deleting an employee. Open up the schema again and add these lines:

```elixir
mutation do

  @desc "Create a new employee"
  field :create_employee, :employee do
    arg :name, non_null(:string)
    arg :status, non_null(:string)

    resolve &EmployeeResolver.create_employee/3
  end

  @desc "Delete an employee"
  field :delete_employee, :employee do
    arg :id, non_null(:id)

    resolve &EmployeeResolver.delete_employee/3
  end

  @desc "Update an employee status"
  field :update_employee_status, :employee do
    arg :id, non_null(:id)
    arg :status, non_null(:string)

    resolve &EmployeeResolver.update_employee_status/3
  end
end
```

Also add these resolvers the EmployeeResolvers module:

```elixir
  def create_employee(_root, args, _info) do
    case Staff.create_employee(args) do
      {:ok, employee} ->
        {:ok, employee}
      _error ->
        {:error, "could not create employee"}
    end
  end

  def delete_employee(_root, %{id: id}, _info) do
    employee = Staff.get_employee!(id)
    case Staff.delete_employee(employee) do
      {:ok, employee} ->
        {:ok, employee}
      _error ->
        {:error, "could not delete employee"}
    end
  end

  def update_employee_status(_root, %{id: id, status: status}, _info) do
    employee = Staff.get_employee!(id)
    case Staff.update_employee(employee,%{status: status}) do
      {:ok, employee} ->
        {:ok, employee}
      _error ->
        {:error, "could not update employee"}
    end
  end
```

Now we are almost ready to test out our graphql endpoint. Fist add the following to your router:

```elixir
    scope "/" do
      pipe_through :api

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: EmployeeStatusWeb.Schema,
        interface: :simple,
        context: %{pubsub: EmployeeStatusWeb.Endpoint}
    end
```

This sets up the graphql playground so we can test our api. Run:

```bash
mix phx.server
```

and point your browswer at http://localhost:4000/graphiql. You should be able to run all the queries and mutations that we set up! Great, now lets try some subscriptions. Lets say we want our dashboard to be notified anytime a user status is updated so we can display that. Lets set up a subscription so that anytime some other client run the update_employee_status mutation our subscription will receive the data of that employee with the updated status. Lets go back to our Schema module and add this:

```elixir
  subscription do
    @desc "Subscribe to any employee status change"
    field :updated_any_employee_status, :employee do
      config fn _, _ ->
       {:ok, topic: :any_employee_updated}
      end
      trigger :update_employee_status, topic: fn _ ->
        :any_employee_updated
      end
    end
  end
```

Also we need to configure pubsub to use Absinthe since that is how subscriptions will be broadcast out. To achieve this we will editing many files. first add this to lib/employee_status_web/channels/user_socket.ex:

```elixir
    defmodule EmployeeStatusWeb.UserSocket do
      use Phoenix.Socket
      # add this line
      use Absinthe.Phoenix.Socket, schema: EmployeeStatusWeb.Schema
```

Now lets add to lib/employee_status_web/endpoint.ex:

```elixir
    defmodule EmployeeStatusWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :employee_status
      # Add this line
      use Absinthe.Phoenix.Endpoint
```

Ok, now lets add to lib/employee_status_web/router.ex:

```elixir
    scope "/" do
      pipe_through :api

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: EmployeeStatusWeb.Schema,
        interface: :simple,
        context: %{pubsub: EmployeeStatusWeb.Endpoint},
        # Add this line
        socket: EmployeeStatusWeb.UserSocket
    end
```

Finally go to lib/employee_status/application.ex and add this line:

```elixir
  def start(_type, _args) do
    children = [
      EmployeeStatus.Repo,
      EmployeeStatusWeb.Telemetry,
      {Phoenix.PubSub, name: EmployeeStatus.PubSub},
      EmployeeStatusWeb.Endpoint,
      # Add this line
      {Absinthe.Subscription, EmployeeStatusWeb.Endpoint}
    ]
```

We have set up subscriptions! We can now restart our server and go back to graphiql and test out our api. I hope this can be a good jumping off point for implementing more complex systems.
