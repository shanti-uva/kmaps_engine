module KmapsEngine
  module PassiveRecord
    extend ActiveSupport::Concern
    include ActiveModel::Model
        
    included do
      attr_accessor :id
    end
    
    module ClassMethods
      
      def create(**attributes)
        @list ||= []
        @next_id ||= 1
        
        item = self.new(**attributes.merge(id: @next_id))
        if !item.nil?
          @list << item
          @next_id += 1
        end
        return item
      end
  
      def find(id)
        i = @list.find_index{ |e| e.id == id }
        return i.nil? ? nil : @list[i]
      end
      
      def where(conditions_hash)
        @list.select do |e|
          condition = true
          conditions_hash.each_pair{|key, value| condition &&= e.send(key)==value }
          condition
        end
      end
  
      def all
        @list
      end
  
      def order(attribute_name)
        @list.sort{|a,b| a.send(attribute_name) <=> b.send(attribute_name) }
      end
    end
  end
end