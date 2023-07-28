defmodule HelloAppTest do
  use ExUnit.Case
  @moduletag timeout: 1_000

  test "say hello to world" do
    tester = create_tester(
      %{
        :command_line_arguments => ["configuration.txt"],
        :remaining_monotonic_time_values => [1000, 1234],
        :file_contents_by_name => %{
          "configuration.txt" => "world"
        },
        :lines_emitted => []
      }
    )

    tester.run.()

    assert tester.lines_emitted.() == ["Hello, world!", "Took 234 microseconds"]
  end

  def create_tester(initial_state) do
    state_process = create_process(initial_state)

    monotonic_time = fn time_unit ->
      send(state_process, {:get_monotonic_time, time_unit, self()})
      receive do
        x -> x
      end
    end

    argv = fn ->
      send(state_process, {:get_argv, self()})
      receive do
        x -> x
      end
    end

    read! = fn file_name ->
      send(state_process, {:get_file_contents, file_name, self()})
      receive do
        x -> x
      end
    end

    puts = fn output_string ->
      send(state_process, {:puts, output_string})
    end

    lines_emitted = fn ->
      send(state_process, {:get_lines_emitted, self()})
      receive do
        x -> x
      end
    end

    system = %{
      :monotonic_time => monotonic_time,
      :argv => argv
    }
    file = %{
      :read! => read!
    }
    io = %{
      :puts => puts
    }
    collaborators = %{
      :system => system,
      :file => file,
      :io => io
    }

    run = fn ->
      HelloApp.main(collaborators)
    end

    %{
      :run => run,
      :lines_emitted => lines_emitted
    }
  end

  def create_process(state) do
    spawn_link(fn -> loop(state) end)
  end

  def consume_monotonic_time(state) do
    [time_value | remaining_time_values ] = state.remaining_monotonic_time_values
    new_state = Map.replace(state, :remaining_monotonic_time_values, remaining_time_values)
    {new_state, time_value}
  end

  def append_line(state, line) do
    new_lines_emitted = [line | state.lines_emitted]
    Map.replace(state, :lines_emitted, new_lines_emitted)
  end

  def loop(state)do
    receive do
      {:get_lines_emitted, caller} ->
        send(caller, Enum.reverse(state.lines_emitted))
        loop(state)
      {:get_monotonic_time, :microsecond, caller} ->
        {new_state, monotonic_time_value} = consume_monotonic_time(state)
        send(caller, monotonic_time_value)
        loop(new_state)
      {:get_argv, caller} ->
        send(caller, state.command_line_arguments)
        loop(state)
      {:get_file_contents, file_name, caller} ->
        file_contents = state.file_contents_by_name[file_name]
        send(caller, file_contents)
        loop(state)
      {:puts, line} ->
        new_state = append_line(state, line)
        loop(new_state)
      x ->
        raise "unmatched pattern #{inspect x}"
    end
  end
end
