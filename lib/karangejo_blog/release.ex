defmodule KarangejoBlog.Release do
      alias KarangejoBlog.Posts.Post
      alias KarangejoBlog.Repo
  
      @app :karangejo_blog 
      
      def migrate do
            for repo <- repos() do
                  {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
            end
      end

      def insert_posts do 
            Application.app_dir(:karangejo_blog, "priv/repo/seeds.exs")
            |> Code.eval_file()
       
      end

      def rollback(repo, version) do
          {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
      end

      defp repos do
          Application.load(@app)
          Application.fetch_env!(@app, :ecto_repos)
      end
  end
