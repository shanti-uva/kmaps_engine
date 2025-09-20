module KmapsEngine
  module ResourceObjectAuthentication
    extend ActiveSupport::Concern
    
    included do
      before_action :redirect_if_unauthorized, only: [:show, :index, :update, :create, :new, :edit]
    end
    
    private
    
    def redirect_back_or_admin
      redirect_to request.referrer || admin_features_url
    end
  
    def redirect_if_unauthorized
      obj = object.nil? ? parent_object : object
      if !(obj.nil? || current_user.object_authorized?(obj))
        message = 'Your user is not authorized to access '
        if obj.nil? || !obj.instance_of?(Feature)
          message << "#{request.fullpath}."
        else
          message << "the admin section for #{Feature.model_name.human} #{object.fid}."
        end
        flash[:notice] = message
        redirect_back_or_admin
      end
    end
    
    module ClassMethods
    end
  end
end
