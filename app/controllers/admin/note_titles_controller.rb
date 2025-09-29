class Admin::NoteTitlesController < ApplicationController
  resource_controller
  before_action :collection
  
  # GET /note_titles
  # GET /note_titles.xml
  def index
    @objects = NoteTitle.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects }
    end
  end

  # GET /note_titles/1
  # GET /note_titles/1.xml
  def show
    @object = NoteTitle.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @object }
    end
  end

  # GET /note_titles/new
  # GET /note_titles/new.xml
  def new
    @object = NoteTitle.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @object }
    end
  end

  # GET /note_titles/1/edit
  def edit
    @object = NoteTitle.find(params[:id])
  end

  # POST /note_titles
  # POST /note_titles.xml
  def create
    @object = NoteTitle.new(params[:note_title])

    respond_to do |format|
      if @object.save
        flash[:notice] = 'Note Title was successfully created.'
        format.html { redirect_to(admin_note_title_url(@object)) }
        format.xml  { render :xml => @object, :status => :created, :location => @object }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @object.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /note_titles/1
  # PUT /note_titles/1.xml
  def update
    @object = NoteTitle.find(params[:id])

    respond_to do |format|
      if @object.update(params[:note_title])
        flash[:notice] = 'Note Title was successfully updated.'
        format.html { redirect_to(admin_note_title_url(@object)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @object.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /note_titles/1
  # DELETE /note_titles/1.xml
  def destroy
    @object = NoteTitle.find(params[:id])
    @object.destroy

    respond_to do |format|
      format.html { redirect_to(admin_note_titles_url) }
      format.xml  { head :ok }
    end
  end
  

  protected

  #
  # Override ResourceController collection method
  #
  def collection
    @collection = NoteTitle.search(params[:filter]).page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def note_title_params
    params.require(:note_title).permit(:title)
  end
end