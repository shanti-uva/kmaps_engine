class Admin::FeaturePidsController < ApplicationController
  # GET /feature_pids
  # GET /feature_pids.xml
  def index
    @message = ''
  end
  
  # GET /feature_pids/available
  # GET /feature_pids/available.xml
  def available
    # @feature_count = Feature.count(:conditions => {:is_blank => true})
    @features = Feature.where(:is_blank => true).order('fid')
    respond_to do |format|
      format.html # available.html.erb
      format.xml  { render :xml => @feature_count.to_xml }
    end
  end
  
  # GET /feature_pids/new
  # GET /feature_pids/new.xml
  def new
    @feature_pid = FeaturePid.new(:count => 1)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @feature_pid }
    end
  end
  
  # POST /feature_pids
  # POST /feature_pids.xml
  def create
    @feature_pid = FeaturePid.new(params[:feature_pid])
    count = @feature_pid.count.to_i
    successful = true
    if count>0
      first = Feature.create(:fid => Feature.generate_pid, :is_blank => true)
      count-=1
    else
      successful = false
    end
    last = nil
    count.times {|i| last = Feature.create(:fid => Feature.generate_pid, :is_blank => true)}
    if successful
      if last.nil?
        @message = "Feature created: #{first.pid}."
      else
        @message = "Range created: #{first.pid} to #{last.pid}."
      end
    else
      @message = "Error creating features!"
    end
    respond_to do |format|
      format.html { render :action => 'index' }
    end    
  end
end