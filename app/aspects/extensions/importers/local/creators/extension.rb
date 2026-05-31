# frozen_string_literal: true

require "dry/monads"
require "initable"

module Terminus
  module Aspects
    module Extensions
      module Importers
        module Local
          module Creators
            # Creates extension.
            class Extension
              include Deps[:logger, "aspects.jobs.schedule", repository: "repositories.extension"]
              include Initable[error_joiner: proc { Terminus::Aspects::Errors::ResultJoiner }]
              include Dry::Monads[:result]

              def initialize(schema: Schemas::Extension, problem: Aspects::Errors::Problem, **)
                @schema = schema
                @problem = problem
                super(**)
              end

              def call attributes
                schema.call(attributes)
                      .to_monad
                      .alt_map { error_joiner.call "Extension", it }
                      .fmap { create it.to_h }
              rescue ROM::SQL::UniqueConstraintError => error
                Failure problem.duplicate(error.message, nil).detail
              end

              private

              attr_reader :schema, :problem

              def create attributes
                if attributes[:kind] == "home_assistant"
                  ha_attributes = extract_home_assistant_attributes attributes
                  repository.create_with_home_assistant attributes, ha_attributes
                else
                  repository.create attributes
                end.tap do |extension|
                  log extension
                  schedule.upsert(*extension.to_schedule)
                end
              end

              def extract_home_assistant_attributes attributes
                {
                  source_mode: attributes.delete(:home_assistant_source_mode) || "entity",
                  entity_ids: attributes.delete(:home_assistant_entity_ids) || [],
                  endpoint_path: attributes.delete(:home_assistant_endpoint_path),
                  attribute_map: attributes.delete(:home_assistant_attribute_map) || {},
                  normalize_urls: extract_normalize_urls(attributes)
                }
              end

              def extract_normalize_urls attributes
                return true unless attributes.key? :home_assistant_normalize_urls

                attributes.delete :home_assistant_normalize_urls
              end

              def log extension
                logger.debug(tags: [{extension_id: extension.id}]) { "Imported extension." }
              end
            end
          end
        end
      end
    end
  end
end
