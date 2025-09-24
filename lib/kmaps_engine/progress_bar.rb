require 'flare/time_utils'

module KmapsEngine
  module ProgressBar
    extend ActiveSupport::Concern
    include Flare::TimeUtils

    STATUS_LENGTH = 36
    FID_LENGTH = 7
    
    included do
      attr_accessor :feature, :log, :bar, :num_errors, :valid_point, :output
    end

    def initialize(log = nil, log_level = nil)
      self.output = STDERR.tty? ? STDERR : STDOUT
      self.reset_progress_bar
      create_log(log, log_level) if !log.nil?
    end

    def create_log(log, log_level)
      if log.instance_of? ActiveSupport::Logger
        self.log = log
      else
        self.log = ActiveSupport::Logger.new(log)
        self.log.level = log_level.nil? ? Rails.logger.level : log_level.to_i
      end
    end

    def close_log
      self.log.close
    end

    def say(msg)
      self.log.error { "#{Time.now}: #{msg}" }
      self.num_errors += 1
      self.valid_point = false
    end

    def reset_progress_bar
      self.bar = ''
      self.valid_point = true
      self.num_errors = 0
    end

    def update_progress_bar(bar:, valid_point:, num_errors:)
      self.bar = bar
      self.valid_point = valid_point
      self.num_errors = num_errors
    end

    def progress_bar(num:, total:, current:)
      if num==total-1
        self.output.printf("\r%-#{STATUS_LENGTH*2}s\n", "\rDone. #{total} items processed with #{self.num_errors} errors.")
        self.reset_progress_bar
      else
        longitude = (num.to_f / total * STATUS_LENGTH).to_i
        if longitude > self.bar.size
          self.bar << (self.valid_point ? '=' : 'X')
          self.valid_point = true
        end
        if output.tty?
          self.output.printf("\rProcessed %-#{FID_LENGTH}s [%-#{STATUS_LENGTH}s]", current, self.bar)
        else
          self.output.puts("Processed #{current} (#{num}/#{total})")
        end
      end
    end
    
    class_methods do
    end
  end
end
