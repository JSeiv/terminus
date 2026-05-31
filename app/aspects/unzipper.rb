# frozen_string_literal: true

require "dry/monads"
require "initable"
require "refinements/string"
require "zip"

module Terminus
  module Aspects
    # A monadic decompressor of zip file content.
    class Unzipper
      include Initable[client: Zip::File]
      include Dry::Monads[:result]

      using Refinements::String

      def self.decompress zip
        zip.each.with_object({}) do |entry, attributes|
          next if entry.directory?

          attributes[entry.name] = entry.get_input_stream.read
        end
      end

      def call io
        client.open_buffer(io) { |zip| break self.class.decompress zip }
              .then { |attributes| Success attributes }
      rescue TypeError, Zip::Error => error
        Failure error.message.up
      end
    end
  end
end
