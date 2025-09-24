module KmapsEngine
  module UserExtensions
    extend ActiveSupport::Concern
    
    included do
      has_and_belongs_to_many :collections, join_table: 'collections_users'
    end
    
    def object_authorized?(o)
      return true if self.admin?
      if o.instance_of?(Feature) 
        o.authorized?(self)
      elsif o.instance_of?(FeatureRelation)
        o.parent_node.authorized_for_descendants?(self)
      else
        o.feature.authorized?(self)
      end
    end
    
    def admin?
      self.role_ids.include? 1
    end
    
    class_methods do
    end
  end
end
