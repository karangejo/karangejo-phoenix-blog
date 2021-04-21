# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     KarangejoBlog.Repo.insert!(%KarangejoBlog.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias KarangejoBlog.Posts.Post
alias KarangejoBlog.Repo

Repo.delete_all(Post)

files = Path.wildcard("./priv/repo/markdown/*.md")
IO.inspect(System.cwd())
IO.inspect(files)
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
