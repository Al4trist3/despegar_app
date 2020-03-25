defmodule CliTest do
  use ExUnit.Case
  

  import Despegar_app.CLI, only: [parse_args: 1]

  test "devuelve :help si se pasa como opcion -h y --help" do
      assert parse_args(["-h", "cualquier cosa"]) == :help
      assert parse_args(["--help", "cualquier cosa"]) == :help
  end


  test "dado tres valores se retornan tres" do
    assert parse_args(["http://localhost", "http://localhost", "prueba.txt"]) == {"http://localhost", "http://localhost", "prueba.txt"}
  end
  
  test "dado dos valores se retorna el valor por defecto del archivo log" do
    assert parse_args(["http://localhost", "http://localhost"]) == {"http://localhost", "http://localhost", "despegarLog.txt"}
  end

end