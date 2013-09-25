require "json"
require "net/http"
require "active_support/core_ext"

module Yandex
  module Direct
    class ApiException < StandardError
      attr_reader :message, :code, :details

      def initialize(message, code, details)
        @message, @code, @details = message, code, details
      end

      def to_s
        "#{code}: #{message}"
      end
    end

    class Api
      attr_reader :token, :login, :app_id, :locale

      def initialize(token, login, app_id, locale = :en)
        @token, @login, @app_id, @locale = token, login, app_id, locale
      end

      def method_missing(method, param = nil)
        request method.to_s.camelize, param
      end


        private

        def request_params(method, param)
          {
            application_id: app_id,
            login: login,
            token: token,
            locale: locale,
            method: method,
            param: param
          }
        end

        def request(method, param)
          request = Net::HTTP::Post.new "/json-api/v4/"
          request.body = request_params(method, param).to_json

          response = Net::HTTP.start("api.direct.yandex.ru", 443, use_ssl: true) do |http|
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            http.request request
          end

          check_error JSON.parse response.body
        end

        def check_error(response)
          if response.try(:[], "error_str")
            raise ApiException.new(response["error_str"], response["error_code"], response["error_detail"])
          end

          response
        end
    end
  end
end