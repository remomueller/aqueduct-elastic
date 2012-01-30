require 'aqueduct'
require 'base64'
require 'net/http'
require 'net/https'

module Aqueduct
  module Repositories
    class Elastic
      include Aqueduct::Repository

      def count_files(file_locators, file_type)
        error = ''
        file_paths = []
        url_paths = []

        file_locators.each do |file_locator|
          file_locator = file_locator.to_s.gsub(/[\/*]/, '') # Don't allow wild cards or subfolders
          file_type = file_type.to_s.gsub(/[\/*]/, '')       # Don't allow wild cards or subfolders
          file_name = file_locator + file_type
          file_paths << file_name unless file_locator.blank?
        end

        # These should be set by the server itself.
        name = "#{@source.name.gsub(/[^\w]/, '')}_#{file_type.split(/[_\.]/).select{|i| not i.blank?}.join('_').downcase}"
        target_file_name = ''
        comments = ''

        result_hash = send_message("downloaders.json", { 'downloader[name]' => name, 'downloader[files]' => file_paths.join("\n"), 'downloader[folder]' => "source_#{@source.id}", 'downloader[comments]' => comments, 'target_file_name' => target_file_name, 'downloader[external_user_id]' => @current_user.id }, "post")
        downloader_hash = result_hash[:result].blank? ? {} : ActiveSupport::JSON.decode(result_hash[:result])
        url_paths = [downloader_hash['simple_executable_file_url']].compact
        file_count = downloader_hash['file_count'].to_i

        error = "Processing...retry in a few minutes." if url_paths.blank?
        { result: file_count, error: error, file_paths: file_paths, urls: url_paths }
      end

      def has_repository?
        { result: true, error: '' }
      end

      def file_server_available?
        result_hash = send_message("about")
        { result: result_hash[:error].blank?, error: result_hash[:error] }
      end

      private

      def send_message(service, form_data = {}, method = "get", limit = 1)
        error = ''
        data = ''
        response = ''
        return { result: data, error: 'HTTP redirect too deep' } if limit < 0

        t_msg_start = Time.now

        service_url = @source.file_server_host + "/" + service

        url = URI.parse(service_url)

        use_secure = (url.scheme == 'https')

        begin
          https = Net::HTTP.new(url.host, url.port)
          https.open_timeout = 1000 # in seconds
          https.read_timeout = 3000 # in seconds
          https.use_ssl = true if use_secure

          headers = { 'Content-Type' => 'text/html', 'WWW-Authenticate' => 'Basic realm="Application"', 'Authorization' => "Basic #{Base64.strict_encode64("#{@source.file_server_login}:#{@source.file_server_password}")}" }

          url = URI.parse(service_url)
          if method == "get"
            req = Net::HTTP::Get.new(url.path, headers)
          elsif method == "post"
            req = Net::HTTP::Post.new(url.path, headers)
          else
            return { error: 'Invalid HTTP Method' }
          end
          req.set_form_data(form_data.stringify_keys, ';') unless form_data.blank?

          https.start do |http|
            response = http.request(req)
          end
          data = response.body

          case response.class.name
          when 'Net::HTTPOK'
          when 'Net::HTTPRedirection'
            return send_message(response['location'].gsub(@source.file_server_host + "/", ''), {}, "get", limit - 1)
            # TODO Test file redirect
            # return send_message(response['location'].gsub(@source.file_server_host + "/", ''), form_data, method, limit - 1)
          else
            error = "Error: #{response.class.name} #{data}"
          end
        rescue => e
          error = e.to_s
          Rails.logger.debug "error: #{error}"
        end

        { result: data, error: error }
      end

    end
  end
end