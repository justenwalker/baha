class Baha::Log
  require 'logger'
  LEVELS = {
      :debug => Logger::DEBUG,
      :info  => Logger::INFO,
      :warn  => Logger::WARN,
      :error => Logger::ERROR,
      :fatal => Logger::FATAL
  }
  class Formatter
    Format = "%s [%5s] %s -- %s\n"

    def call(severity, time, progname, msg)
      Format % [time.strftime('%Y-%m-%d %H:%M:%S.%L'), severity, progname, msg2str(msg)]
    end

    private

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n\t" <<
          (msg.backtrace || []).join("\n\t")
      else
        msg.inspect
      end
    end
  end
  class << self
    attr_reader :level, :logfile, :io
    def logfile=(io)
      @io = io
      @logfile = Logger.new(io)
      @logfile.formatter = Baha::Log::Formatter.new()
      self.level = :error
    end
    def level=(level)
      key = case level
      when String
        @level = level.downcase.to_sym
      when Symbol
        @level = level.downcase
      else
        raise ArgumentError.new("level must be a string or symbol")
      end
      raise ArgumentError.new("level must be in #{LEVELS.keys}") unless LEVELS.has_key?(key)
      @level = key
      self.logfile.sev_threshold = LEVELS[@level]
    end
    def close!
      if @logfile
        @logfile.close
        @logfile = nil
      end
    end
    def for_name(progname)
      Baha::Log.new(progname)
    end
  end

  attr_reader :progname

  def initialize(progname)
    @progname = progname
  end

  LEVELS.keys.each do |level|
    define_method(level) do |*message, &block|
      if Baha::Log.logfile
        if block
          Baha::Log.logfile.send(level, @progname, &block)
        else
          Baha::Log.logfile.send(level, @progname) { message[0] }
        end
      end
    end
  end
end