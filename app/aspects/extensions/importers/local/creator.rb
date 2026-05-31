# frozen_string_literal: true

require "core"
require "dry/monads"
require "initable"
require "yaml"

module Terminus
  module Aspects
    module Extensions
      module Importers
        module Local
          # Creates extension from zip file export.
          class Creator
            include Deps[
              "aspects.unzipper",
              extension_creator: "aspects.extensions.importers.local.creators.extension",
              exchange_creator: "aspects.extensions.importers.local.creators.exchange"
            ]
            include Initable[
              key_map: {
                "configuration.yml" => :configuration,
                "template.html.liquid" => :template,
                "home_assistant.yml" => :home_assistant
              }
            ]
            include Dry::Monads[:result]

            def initialize(schema: Schemas::Import, error_joiner: Errors::ResultJoiner, **)
              @schema = schema
              @error_joiner = error_joiner
              super(**)
            end

            # :reek:TooManyStatements
            # rubocop:todo Metrics/AbcSize
            def call io, attributes: {}
              unzipper.call(io)
                      .fmap { |entries| transform entries }
                      .fmap { attributes.replace it }
                      .bind { schema.call(it).to_monad }
                      .alt_map { error_joiner.call "Import", it }
                      .bind { extension_creator.call attributes }
                      .bind { create_exchanges it, attributes }
            end
            # rubocop:enable Metrics/AbcSize

            private

            attr_reader :schema, :error_joiner

            def transform entries
              manifest = normalize_manifest entries
              payload = merge_home_assistant(
                YAML.load(manifest.fetch(:configuration)),
                manifest[:home_assistant]
              )

              {**manifest, **payload}
            end

            def normalize_manifest entries
              entries.each_with_object({}) do |(name, content), manifest|
                key = File.basename name
                mapped = key_map.fetch key, key.to_sym
                manifest[mapped] = content
              end
            end

            def merge_home_assistant configuration, home_assistant
              return configuration unless home_assistant

              settings = YAML.load(home_assistant) || {}

              configuration.merge(
                "home_assistant_source_mode" => settings["source_mode"],
                "home_assistant_entity_ids" => settings["entity_ids"],
                "home_assistant_endpoint_path" => settings["endpoint_path"],
                "home_assistant_attribute_map" => settings["attribute_map"],
                "home_assistant_normalize_urls" => settings["normalize_urls"]
              )
            end

            def create_exchanges extension, attributes
              attributes.fetch("exchanges", Core::EMPTY_ARRAY)
                        .reduce(Success(extension)) { |result, item| create_exchange result, item }
            end

            def create_exchange result, attributes
              result.bind do |extension|
                exchange_creator.call(attributes.merge!(extension_id: extension.id))
                                .fmap { extension }
              end
            end
          end
        end
      end
    end
  end
end
