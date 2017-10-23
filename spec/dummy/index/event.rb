module Index
  class Event
    include Mindex::Index

    def self.scroll(options = {})
      DB[:events].select.each do |event|
        yield event
      end
    end
  end
end
