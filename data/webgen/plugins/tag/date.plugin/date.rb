module Tag

  # Prints out the date using a format string which will be passed to Time#strftime. Therefore you
  # can use everything Time#strftime offers.
  class Date < DefaultTag

    def process_tag( tag, body, context )
      Time.now.strftime( param( 'format' ) )
    end

  end

end
