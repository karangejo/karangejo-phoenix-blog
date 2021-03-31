defmodule KarangejoBlog.Release do
      @app :karangejo_blog 
      
      def migrate do
            for repo <- repos() do
                  {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
            end
      end

      def insert_posts do 
            files =
                  Application.app_dir(:karangejo_blog, "priv/repo/markdown/*.md") 
                  |> Path.wildcard
                  
            Enum.map(files, fn file ->
                  case File.read(file) do
                    {:ok, content} ->
                      post_name =
                        Path.basename(file)
                        |> String.replace(".md","")
                        |> String.replace("_"," ")
                      
                      Repo.insert!(%Post{name: post_name, content: content})
                    _ ->
                      IO.puts("could not insert file : " ++ file)
                  end
            end)
      end

      def rollback(repo, version) do
          {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
      end

      defp repos do
          Application.load(@app)
          Application.fetch_env!(@app, :ecto_repos)
      end
  end
