#
# This helper forces the admin/simple_props views to be used for any < SimpleProp class controller
#
module KmapsEngine
  module SimplePropsControllerHelper
    extend ActiveSupport::Concern
    
    included do
      helper 'Admin'
      
      index.wants.html      { render 'admin/simple_props/index' }
      show.wants.html       { render 'admin/simple_props/show'  }
      new_action.wants.html { render 'admin/simple_props/new'   }
      edit.wants.html       { render 'admin/simple_props/edit'  }
    end
    
    def initialize
      super
      @guest_perms = []
    end
    
    def collection
      @collection = model_name.classify.constantize.search(params[:filter]).page(params[:page]).order('UPPER(name)')
    end
  end
end