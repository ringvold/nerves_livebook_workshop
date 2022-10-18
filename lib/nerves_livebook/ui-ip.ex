defmodule NervesLivebook.UIScreen do
  @moduledoc """
    # https://hexdocs.pm/chisel/readme.html
    # fork of: https://github.com/pappersverk/oled
  """
  use GenServer

  require Logger

  # Pixel draw function
  defp put_pixel(x, y) do
    NervesLivebook.OLED.put_pixel(x, y)
  end

  defp write_only(text) do
    # Load font
    {:ok, font} = Chisel.Font.load("/fonts/cure.bdf")
    NervesLivebook.OLED.clear()

    Chisel.Renderer.draw_text(text, 10, 10, font, fn x, y -> put_pixel(x, y) end, size_x: 2, size_y: 2)

    NervesLivebook.OLED.display()
  end

  defp clear_screen do
    NervesLivebook.OLED.clear()
    NervesLivebook.OLED.display()
  end

  defp get_ip do
    VintageNet.get(["interface", "wlan0", "addresses"])
      |> Enum.filter(fn x -> x[:family] == :inet end)
      |> Enum.at(0)
      |> Map.fetch!(:address)
      |> Tuple.to_list()
      |> Enum.map(fn x -> Integer.to_string(x) end)
      |> Enum.join(".")
  end


  @doc """
  Start the UI GenServer

  Options:
    * None
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    VintageNet.subscribe(["connection"])
    value = VintageNet.get(["connection"])

    write_only("Connecting.")

    {:ok, :no_state}
  end

  @impl GenServer
  def handle_info({VintageNet, ["connection"], _old, value, _meta}, state) do
    led_program(value)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp led_program(:internet) do
    write_only("Connected")
    Process.sleep(500)
    write_only(get_ip())
    Process.sleep(10000)
  end
  defp led_program(:lan) do
    write_only("lan")
  end
  defp led_program(_disconnected) do
    write_only("disconnected")
  end
end

