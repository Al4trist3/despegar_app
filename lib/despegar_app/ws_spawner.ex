defmodule WS_Spawner do

    @max_pages 1000
    
    def generate(get_url, post_url, file_name) do

        path = Path.join(System.user_home!, file_name)
        {:ok, file} = File.open(path,[:write, :utf8])

        supervisor = spawn(WS_Spawner, :supervise, [0, 0, self()])
        
        for page <- 1..@max_pages do
            spawn(Despegar_app.WSTaxLogger, :run, [get_url, post_url, file, page, supervisor])
        end

        receive do
            {:ok, processed} ->
                File.close(file)
                IO.puts("Se procesaron #{processed} clientes")
        end

    end

    def supervise(count, total_processed, pid) when count == @max_pages do
        
        send(pid, {:ok, total_processed})

    end

    def supervise(count, total_processed, pid) do

        receive do
            {_, processed} -> supervise(count + 1, total_processed + processed , pid)
        end
        
    end
    
end