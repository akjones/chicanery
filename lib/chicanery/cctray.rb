require 'chicanery/http'
require 'nokogiri'
require 'date'

module Chicanery
  module Cctray
    def self.new *args
      Cctray::Server.new *args
    end

    def cctray *args
      server Cctray::Server.new *args
    end

    class Server
      include Chicanery::Http
      attr_reader :name, :uri, :options

      def initialize name, url, options={}
        @name, @uri, @options = name, URI(url), options
      end

      def jobs
        jobs = {}
        response_body = get uri, options
        Nokogiri::XML(response_body).css("Project").each do |project|
          job = {
            activity: project[:activity] == 'Sleeping' ? :sleeping : :building,
            last_build_status: parse_build_status(project[:lastBuildStatus]),
            last_build_time: project[:lastBuildTime].empty? ? nil : DateTime.parse(project[:lastBuildTime]).to_time.to_i,
            url: project[:webUrl],
            last_label: project[:lastBuildLabel]
          }
          jobs[project[:name]] = job unless filtered project[:name]
        end
        raise "could not find any jobs in response: [#{response_body}]" if jobs.empty?
        jobs
      end

      def parse_build_status status
        case status
        when /^Success/ then :success
        when /^Unknown/ then :unknown
        else :failure
        end
      end

      def filtered name
        return false unless options[:include]
        !options[:include].match(name)
      end
    end
  end
end
