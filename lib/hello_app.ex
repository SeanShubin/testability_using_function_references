defmodule HelloApp do
  def main() do
    system = %{
      :monotonic_time => &System.monotonic_time/1,
      :argv => &System.argv/0
    }
    file = %{
      :read! => &File.read!/1
    }
    io = %{
      :puts => &IO.puts/1
    }
    collaborators = %{
      :system => system,
      :file => file,
      :io => io
    }
    Hello.main(collaborators)
  end
end
