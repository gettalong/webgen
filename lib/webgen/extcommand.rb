require "tempfile"

# Allows one to get stdout and stderr from an executed command. Original version
# by Karl von Laudermann in ruby-talk #113035
class ExtendedCommand

  attr_reader :ret_code, :out_text, :err_text

  def initialize( command )
    tempfile = Tempfile.new( 'webgen' )
    tempfile.close  # So that child process can write to it

    # Execute command, redirecting stderr to temp file
    @out_text = `#{command} 2> #{tempfile.path}`
    @ret_code = $? >> 8

    # Read temp file
    tempfile.open
    @err_text = tempfile.readlines.join
    tempfile.close
  end

end
