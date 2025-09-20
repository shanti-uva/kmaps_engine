#
# This module can be extended by any ActiveRecord
# class that needs notes
#
module KmapsEngine
  module IsNotable
    extend ActiveSupport::Concern
    
    included do
      has_many :notes, :as => :notable, :dependent => :destroy
    end
    
    def public_notes
      notes.where(:is_public => true)
    end
  end
end
