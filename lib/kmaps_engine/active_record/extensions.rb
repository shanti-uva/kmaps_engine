module KmapsEngine
  module ActiveRecord
    module Extensions
      extend ActiveSupport::Concern
      
      included do
      end
      
      def per_page
        10
      end
      
      module ClassMethods
        #
        # generic helper method used for building "LIKE" conditions
        # on mulitple columns, using a single filter value
        #
        def build_like_conditions(fields, filter_value, **options)

          #
          # if filter_value is blank, no point in building the LIKE conditions
          #
          return nil if filter_value.blank?

          # Determine what kind of a match should be performed
          match = case options[:match]
          when "begins"
            "#{filter_value}%"
          when "ends"
            "%#{filter_value}"
          when "exactly"
            "#{filter_value}"
          else
            "%#{filter_value}%"
          end

          # conditions[0] is the sql/LIKE fragments
          # the rest of the items in "conditions" must be values that sequentially
          # bind to the various "?" statement placeholders
          conditions=[[]]

          # FIXME: PostgreSQL-specific ILIKE command
          fields.each do |field|
            conditions[0] << "#{field} ILIKE ?"
            conditions << match
          end

          #
          # convert LIKE fragments to sql (string)
          #
          conditions[0]=conditions[0].join(' OR ')
          conditions

          # Note: this function's "return_all=true" argument was removed so that a more general "options"
          # could be used.  To re-implement the code below, it should be modified to use options instead
          # of return_all.

          # no filter value and return all, disregards is_public
          # return nil if filter_value.blank? && return_all
          # 
          # return ['is_public = 1'] if filter_value.blank? && !return_all
          # 
          # conditions=[]
          # index = 0
          # unless return_all
          #   conditions << 'is_public = 1'
          #   index += 1
          # end
          # 
          # conditions[index]=''
          # sep=''
          # fields.each do |field|
          #   conditions[index] += (sep + "#{field} LIKE ?")
          #   sep = ' OR '
          #   conditions << "%#{filter_value}%"
          # end
          # conditions
        end
      end 
    end
  end
end
