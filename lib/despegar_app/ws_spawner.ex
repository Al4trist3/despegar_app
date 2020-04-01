defmodule Despegar_app.WS_Spawner do
    use Supervisor
    @max_pages 1000
    @max_concurrency 10

    
    def start_link(args) do
        Supervisor.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(get_url, post_url, file_name) do
        children = [
            {Task.Supervisor, name: Despegar_app.TaskSupervisor, restart: :temporary}
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end

    
    def generate(get_url, post_url, file_name) do

        path = Path.join(System.user_home!, file_name)
        {:ok, file} = File.open(path,[:write, :utf8])

        tasks = for page <- 1..@max_pages do
            %Despegar_app.WSTaxLogger{get_url: get_url, post_url: post_url, file_name: file_name, page: page}
        end
        
        processed = Task.Supervisor.async_stream(Despegar_app.TaskSupervisor, tasks, Despegar_app.WSTaxLogger, :run, [],  max_concurrency: @max_concurrency)
        |> Enum.filter(fn {c, _} -> c: == ok end)
        |> Enum.reduce(fn {_, r}, {_, r2} -> r + r2 end)

        File.close(file)
        IO.puts("Se procesaron #{processed} clientes")


    end

end