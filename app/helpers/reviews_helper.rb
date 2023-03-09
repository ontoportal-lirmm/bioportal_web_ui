module ReviewsHelper
  def organize_ratings(review)
    return [
             { name: :usability, value: review.usabilityRating.to_i },
             { name: :coverage, value: review.coverageRating.to_i },
             { name: :quality, value: review.qualityRating.to_i },
             { name: :formality, value: review.formalityRating.to_i },
             { name: :correctness, value: review.correctnessRating.to_i },
             { name: :documentation, value: review.documentationRating.to_i },
           ]
  end
end
