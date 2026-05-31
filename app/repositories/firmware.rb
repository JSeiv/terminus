# frozen_string_literal: true

module Terminus
  module Repositories
    # The firmware repository.
    class Firmware < DB::Repository[:firmware]
      include Deps[:shrine, model_repository: "repositories.model"]

      commands :create

      commands update: :by_pk,
               use: :timestamps,
               plugins_options: {timestamps: {timestamps: :updated_at}}

      def all = firmware.by_version_desc.to_a

      def delete id
        find(id).then { it.attachment_destroy if it }

        firmware.by_pk(id).delete
      end

      def delete_all
        firmware.where { attachment_data.has_key "id" }
                .select { attachment_data.get_text("id").as(:attachment_id) }
                .map(:attachment_id)
                .each { shrine.storages[:store].delete it }

        firmware.delete
      end

      def find(id) = (firmware.by_pk(id).one if id)

      def find_by(**) = firmware.where(**).one

      def latest = all.first

      def latest_for device
        model = resolve_model device
        return latest unless model

        kinds = [model.name, model.kind, "terminus"].compact.uniq

        firmware.where(kind: kinds).by_version_desc.first
      end

      def resolve_model device
        return unless device

        model = device.respond_to?(:model) ? device.model : nil
        return model if model

        model_id = device.respond_to?(:model_id) ? device.model_id : nil
        return unless model_id

        model_repository.find model_id
      end

      def search key, value
        firmware.where(Sequel.like(key, "%#{value}%"))
                .order { created_at.asc }
                .to_a
      end
    end
  end
end
