# auto_register: false
# frozen_string_literal: true

module Terminus
  module Aspects
    module Extensions
      module Importers
        module Local
          module Schemas
            # Defines import schema.
            Extension = Dry::Schema.Params do
              required(:name).filled :string
              required(:label).filled :string
              required(:description).maybe :string
              required(:mode).filled :string
              required(:kind).filled :string
              required(:tags).maybe :array
              required(:static_body).maybe :hash
              required(:template).filled :string
              required(:fields).maybe :array
              required(:data).maybe :hash
              required(:interval).maybe :integer
              required(:unit).filled :string
              required(:days).maybe :array
              required(:last_day_of_month).filled :bool
              required(:start_at).filled :date_time

              optional(:home_assistant_source_mode).filled :string
              optional(:home_assistant_entity_ids).maybe :array
              optional(:home_assistant_endpoint_path).maybe :string
              optional(:home_assistant_attribute_map).maybe :hash
              optional(:home_assistant_normalize_urls).filled :bool
            end
          end
        end
      end
    end
  end
end
