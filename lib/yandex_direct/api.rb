require "json"
require "net/http"
require "active_support/core_ext"

module Yandex
  module Direct
    class Api
      attr_reader :token, :login, :app_id, :locale

      def initialize(token, login, app_id, locale = :en)
        @token, @login, @app_id, @locale = token, login, app_id, locale
      end

      def method_missing(method, *args)
        request method.to_s.camelize, args
      end


        private

        def request_params(method, params)
          {
            application_id: app_id,
            login: login,
            token: token,
            locale: locale,
            method: method,
            params: params
          }
        end

        def request(method, params)
          request = Net::HTTP::Post.new "/json-api/v4/"
          request.body = request_params(method, params).to_json
            
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