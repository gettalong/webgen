
class ThgException < RuntimeError

    attr_reader :solution

    def initialize( id, *args )
        super( substitute_entries( id, 0, args ) )
        @solution = substitute_entries( id, 1, args )
    end

    def substitute_entries( id, msgIndex, *args )
        args.flatten!
        @@messageMap[id][msgIndex].gsub( /%(\d+)/ ) do |match|
            args[$1.to_i].to_s
        end
    end

    private :substitute_entries

    ### Class variables and methods ###

    @@messageMap = Hash.new

    def ThgException.add_entry( symbol, message, solution )
        raise ThgException.new( :EXCEPTION_SYMBOL_IS_DEFINED, symbol, caller[0] ) if @@messageMap.has_key? symbol
        @@messageMap[symbol] = [message, solution]
    end

    ThgException.add_entry :EXCEPTION_SYMBOL_IS_DEFINED,
        "the symbol %0 is already defined (%1)",
        "change the name of the symbol"

end

