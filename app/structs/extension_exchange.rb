# frozen_string_literal: true

module Terminus
  module Structs
    # The extension exchange struct.
    class ExtensionExchange < DB::Struct
      def export_attributes = {headers:, verb:, body:, template:}

      def http_attributes = {headers:, verb:, body:}
    end
  end
end
