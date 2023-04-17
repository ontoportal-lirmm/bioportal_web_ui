class ReviewsController < ApplicationController

  layout false # this controller is intended to use only through XHR so we don't need layout

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
  end

  # GET /reviews/1/edit
  def edit
    @rating_types = RATING_TYPES
    @review = LinkedData::Client::Models::Review.find(review_id_from_params)
    @ontology = LinkedData::Client::Models::Ontology.find(@review.ontologyReviewed)
  end

  def create
    @review = LinkedData::Client::Models::Review.new(values: params[:review])
    @ontology = LinkedData::Client::Models::Ontology.find(@review.ontologyReviewed)
    @review_saved = @review.save
    if response_error?(@review_saved)
      @errors = response_errors(@review_saved)
      render :action => "new"
    else
      @review = review_saved
      render action: 'show', status: :created
    end
  end

  # PUT /reviews/1
  # PUT /reviews/1.xml
  def update
    @review = LinkedData::Client::Models::Review.find(review_id_from_params)
    if @review.update_from_params(review_params)
      review_saved = @review.update

      if review_saved&.errors
        render json: response_errors(review_saved), status: :bad_request
      else
        render :action=>'show', status: :ok
      end
    else
      render :action => "edit"
    end
  end

  # DELETE /reviews/1
  # DELETE /reviews/1.xml
  def destroy
    review = LinkedData::Client::Models::Review.find(review_id_from_params)
    deletedReview = review.delete

    if deletedReview&.errors
      render json: response_errors(deletedReview), status: :internal_server_error
    else
      render json: {}, status: :ok
    end
  end

  private

  def review_id_from_params
    review_id = "#{LinkedData::Client.settings.rest_url}/reviews/#{params[:id]}"
  end

  def review_params
    p = params.require(:review).permit(:ontologyReviewed, :creator, :body, *RATING_TYPES)
    p.to_h
  end
end
