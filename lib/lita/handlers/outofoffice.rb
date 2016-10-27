require 'date'

module Lita
  module Handlers
    class Outofoffice < Handler

      route(/^ooo\s(.+)/i, :setOOO, command: true, help: { "ooo" => "Set days you will be out of office, ie 'ooo from today until Friday'"})
      route(/^ooo delete/i, :delOOO, command: true, help: { "ooo delete" => "Deletes the Out Of Office data for your user"})
      route(/@/i, :isOOO, command: false)

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

      def checkOOO(out, back)
	now = DateTime.now.to_date
        if now >= out and now <= back
          (back - out).to_i
        else
          0
        end
      end

      def setOOO(response)
	begin
	  from=dateCheck(fromDate(response.message.body))
	  to=dateCheck(toDate(response.message.body))

	  if DateTime.parse(from) > DateTime.parse(to)
	    raise ArgumentError
	  end	

	  out = { out: from, in: to }
          redis.set(response.user.mention_name, out)

          response.reply("Okay #{response.user.name}, I've got you marked as Out of Office from #{from} until #{to}")
	rescue ArgumentError
          response.reply("Something about your dates look funny to me. Fix it and try again")
        end
      end

      def delOOO(response)
        redis.del(response.user.mention_name)
        response.reply("I've removed your Out Of Office data #{response.user.name}")
      end

      def isOOO(response)
	response.message.body.split(" ").each { |w|
	  if w.include? "@" and w.include? "jbrunsek"
	    data = eval(redis.get(w.split('@')[1]))
            #response.reply(data[:out]}
	    if !data[:out].nil?
	      duration = checkOOO(DateTime.parse(data[:out]), DateTime.parse(data[:in]))
	      if duration > 7
                response.reply("#{w} is currently out of office until...#{DateTime.parse(data[:in]).strftime("%b %d")}?! Are we still paying this human?")
	      elsif duration > 0
                if response.message.body.include? "?"
                  response.reply("#{w} is currently out of office. They needed a break because you ask them too many questions.")
                else
		  response.reply("It looks like #{w} is currently out of office and won't be back until #{data[:in]}")
		end
	      end
            end
	  end
	}
      end

      Lita.register_handler(self)
    end
  end
end
