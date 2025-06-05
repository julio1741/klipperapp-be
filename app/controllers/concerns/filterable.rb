module Filterable
  extend ActiveSupport::Concern

  included do
    scope :filter_by_params, ->(params) {
      results = all
      params.each do |key, value|
        if column_names.include?(key)
          results = results.where(key => value)
        end
      end
      results
    }
  end
end
