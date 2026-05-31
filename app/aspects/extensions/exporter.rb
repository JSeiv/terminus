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

          return zipper.call manifest unless home_assistant? extension

          manifest["home_assistant.yml"] = home_assistant_configuration_for extension
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

        def home_assistant_configuration_for extension
          config = ha_config_repository.find_by_extension_id extension_id: extension.id

          YAML.dump home_assistant_configuration_payload(config), stringify_names: true
        end

        def home_assistant?(extension) = extension.kind == "home_assistant"

        def home_assistant_configuration_payload config
          {
            source_mode: config_source_mode(config),
            entity_ids: config_entity_ids(config),
            endpoint_path: config_endpoint_path(config),
            attribute_map: config_attribute_map(config),
            normalize_urls: config_normalize_urls(config)
          }
        end

        def config_source_mode(config) = config ? config.source_mode : "entity"

        def config_entity_ids(config) = config ? config.entity_ids : []

        def config_endpoint_path(config) = config ? config.endpoint_path : nil

        def config_attribute_map(config) = config ? config.attribute_map : {}

        def config_normalize_urls config
          return true unless config
          return true if config.normalize_urls.nil?

          config.normalize_urls
        end
      end
    end
  end
end
