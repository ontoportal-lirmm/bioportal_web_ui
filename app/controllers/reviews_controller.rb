class ReviewsController < ApplicationController

  layout 'ontology_viewer'

  RATING_TYPES = [
    :usabilityRating,
    :coverageRating,
    :qualityRating,
    :formalityRating,
    :correctnessRating,
    :documentationRating
  ].freeze

  def new
    @rating_types = RATING_TYPES
    @ontology = LinkedData::Client::Models::Ontology.find(params[:ontology])
    @review = LinkedData::Client::Models::Review.new(values: {ontologyReviewed: @ontology.id, creator: session[:user].id})

    if request.xhr?
      render layout: false
    end
  end

  # GET /reviews/1/edit
  def edit
    @review = Review.find(params[:id])
    @rating_types = RatingType.all

    if request.xhr?
      render layout: false
    end
  end

  def create
    @review = LinkedData::Client::Models::Review.new(values: params[:review])
    @ontology = LinkedData::Client::Models::Ontology.find(@review.ontologyReviewed)
    @review_saved = @review.save
    if response_error?(@review_saved)
      @errors = response_errors(@review_saved)
      render :action => "new"
    else
      respond_to do |format|
        format.html do
          flash[:notice] = 'Review was successfully created'
          redirect_to "/ontologies/#{@ontology.acronym}?p=summary"
        end
        format.js do
          render json: {}
        end
      end
    end
  end

  # PUT /reviews/1
  # PUT /reviews/1.xml
  def update
    @review = Review.find(params[:id])
    ratings = Hash[*(@review.ratings.map{|rate| [rate.id.to_i, rate] }.flatten)]
    #puts ratings.inspect
     for rating_key in params.keys
        if rating_key.include?("star")
          #puts rating_key.split("_")[1].to_i
          ratings[rating_key.split("_")[1].to_i].value=params[rating_key].to_i
          ratings[rating_key.split("_")[1].to_i].save
        end
      end
      if @review.update_attributes(params[:review])
        @review.reload
         if request.xhr?
            render :action=>'show', :layout=>false
          else
            redirect_to reviews(:ontology=>review.ontology_id)
          end
      else
        render :action => "edit"
      end
  end

  # DELETE /reviews/1
  # DELETE /reviews/1.xml
  def destroy
    @review = Review.find(params[:id])
    @review.destroy

    respond_to do |format|
      format.html { redirect_to(reviews_url) }
      format.xml  { head :ok }
    end
  end
end
