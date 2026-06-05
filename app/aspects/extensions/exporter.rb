# frozen_string_literal: true

require "yaml"

module Terminus
  module Aspects
    module Extensions
      # Exports extension attributes for sharing.
      class Exporter
        include Deps[
          :settings,
          "aspects.zipper",
          exchange_repository: "repositories.extension_exchange",
          ha_config_repository: "repositories.extension_home_assistant_config"
        ]

        def call extension
          manifest = {
            "configuration.yml" => configuration_for(extension),
            "template.html.liquid" => extension.template
          }

          # rubocop:disable Style/MissingElse
          if home_assistant? extension
            manifest["home_assistant.yml"] = home_assistant_configuration_for extension
          end
          # rubocop:enable Style/MissingElse

          zipper.call manifest
        end

        private

        def configuration_for extension
          YAML.dump build_configuration(extension), stringify_names: true
        end

        def build_configuration extension
          exchange_repository.where(extension_id: extension.id)
                             .map(&:export_attributes)
                             .then do |exchanges|
                               {
                                 version: settings.git_tag,
                                 **extension.export_attributes,
                                 exchanges:
                               }
                             end
        end

        def home_assistant?(extension) = extension.kind == "home_assistant"

        def home_assistant_configuration_for extension
          config = ha_config_repository.find_by_extension_id extension_id: extension.id
          return YAML.dump default_home_assistant_payload, stringify_names: true unless config

          YAML.dump home_assistant_payload(config), stringify_names: true
        end

        def home_assistant_payload config
          normalize_urls = config.normalize_urls

          {
            source_mode: config.source_mode || "entity",
            entity_ids: config.entity_ids || [],
            endpoint_path: config.endpoint_path,
            attribute_map: config.attribute_map || {},
            normalize_urls: normalize_urls.nil? || normalize_urls
          }
        end

        def default_home_assistant_payload
          {
            source_mode: "entity",
            entity_ids: [],
            endpoint_path: nil,
            attribute_map: {},
            normalize_urls: true
          }
        end
      end
    end
  end
end
