#
# This module can be extended by any ActiveRecord
# class that needs timespans
#
module KmapsEngine
  module HasTimespan
    def self.extended(base)

      base.has_one :timespan, :as=>:dateable, :dependent => :destroy

      base.class_eval do
        #
        # Make sure a default timespan is available
        #
        alias :_timespan timespan
        def timespan
          self._timespan.nil? ? build_timespan(:is_current=>true) : _timespan
        end

        #
        # Allow a timespan to be updated/create
        #
        def timespan_attributes=(timespan_attrs)
          self.timespan ? self.timespan.update(timespan_attrs) : self.build_timespan(timespan_attrs)
        end
      end
    end
  end
end