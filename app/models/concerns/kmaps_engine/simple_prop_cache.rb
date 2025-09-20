module KmapsEngine
  module SimplePropCache
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def get_all
        self.order('created_at').all
      end

      def get_by_code(code)
        prop_id = Rails.cache.fetch("#{self.name}-code/#{code}", :expires_in => 1.day) do
          prop = self.find_by(code: code)
          prop.nil? ? nil : prop.id
        end
        prop_id.nil? ? nil : self.find(prop_id)
      end

      def get_by_name(name)
        prop_id = Rails.cache.fetch("#{self.name}-name/#{name}", :expires_in => 1.day) do
          prop = self.find_by(name: name)
          prop.nil? ? nil : prop.id
        end
        prop_id.nil? ? nil : self.find(prop_id)
      end

      def get_by_code_or_name(code, name)
        if code.blank?
          code = nil if !code.nil?
          prop = name.blank? ? nil : self.get_by_name(name)
        else
          name = nil if !name.nil?
          prop = code.blank? ? nil : self.get_by_code(code)
        end
        if prop.nil?
          identifier = code || name
          raise "#{self.model_name.human.capitalize} #{identifier} not found." if !identifier.blank?
        end
        prop
      end
    end
  end
end