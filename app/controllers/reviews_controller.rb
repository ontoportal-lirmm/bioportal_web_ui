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

  def index

  end

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
    @review = LinkedData::Client::Models::Review.new(values: review_params)
    @ontology = LinkedData::Client::Models::Ontology.find(@review.ontologyReviewed)
    @review_saved = @review.save

    respond_to do |format|
      if @review_saved.errors
        @errors = response_errors(@review_saved)
        @rating_types = RATING_TYPES
        format.html { render action: "new", layout: false }
        format.json { render json: @errors, status: :unprocessable_entity }
      else
        flash[:notice] = 'Review was successfully created'
        redirect_path = "/ontologies/#{@ontology.acronym}?p=summary"
        format.html { redirect_to redirect_path }
        format.js { render js: "window.location ='#{redirect_path}'" }
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
        if rating_key.include?('star')
          #puts rating_key.split("_")[1].to_i
          ratings[rating_key.split('_')[1].to_i].value=params[rating_key].to_i
          ratings[rating_key.split('_')[1].to_i].save
        end
      end
      if @review.update_attributes(review_params)
        @review.reload
         if request.xhr?
            render :show, layout: false
          else
            redirect_to reviews(ontology: review.ontology_id)
          end
      else
        render :edit
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

  private
  def review_params
    p = params[:review].permit(:ontologyReviewed, :creator, :usabilityRating,
                               :coverageRating, :qualityRating, :formalityRating,
                               :correctnessRating, :documentationRating, :body)
    p.to_h
  end
end
