require 'date'

module Lita
  module Handlers
    class Outofoffice < Handler

      route(/^ooo\s(.+)/i, :setOOO, command: true, help: { "ooo" => "Set out of office response"})

      def fromDate(str)
      	str[/#{Regexp.escape("from ")}(.*?)#{Regexp.escape(" until")}/m, 1]
      end

      def toDate(str)
        str.split("until ")[-1]
      end

      def dateCheck(str)
        case str.downcase
          when "today","now"
	    date = DateTime.now.to_date
	  when "tomorrow"
	    date = DateTime.now.next.to_date
	  else
	    date = DateTime.parse(str)
	end
	date.strftime("%Y-%m-%d")
      end

      def setOOO(response)
	begin
	  from=dateCheck(fromDate(response.message.body))
	  to=dateCheck(toDate(response.message.body))

	  if DateTime.parse(from) > DateTime.parse(to)
	    raise ArgumentError
	  end	

	  out = { out: from, in: to }
          redis.set(response.user.name, out)

          response.reply("Okay #{response.user.name}, I've got you marked as Out of Office from #{from} until #{to}")
	rescue ArgumentError
          response.reply("Something about your dates look funny to me. Fix it and try again")
        end
      end

      Lita.register_handler(self)
    end
  end
end
