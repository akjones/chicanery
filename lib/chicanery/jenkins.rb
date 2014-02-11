require 'chicanery/site'
require 'nokogiri'
require 'date'

module Chicanery
  module Jenkins
    def self.new *args
      Jenkins::Server.new *args
    end

    def jenkins *args
      server Jenkins::Server.new *args
    end

    class Server < Chicanery::Site
      def jobs
        jobs = {}
        response_body = get

        parsed = Nokogiri::XML(response_body)

        job = {
          activity: parsed.css('building').text == 'false' ? :sleeping : :building,
          last_build_status: parse_build_status(parsed.css('result').text),
          last_build_time: parse_build_time(parsed.css('duration').text.to_i),
          url: parsed.css('url').text,
          last_label: parsed.css('buildNumber').text
        }

        jobs["woo"] = job
        
        jobs
      end

      def parse_build_time time
        return nil if time.nil?
        time/60
      end

      def parse_build_status status
        case status
        when /^SUCCESS/ then :success
        when /^UNKNOWN/ then :unknown
        else :failure
        end
      end
    end
  end
end
