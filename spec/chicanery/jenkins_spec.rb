require 'chicanery/jenkins'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
end

describe Chicanery::Jenkins do
  let(:server) do
    Chicanery::Jenkins.new 'jruby', 'http://ci.jruby.org/job/jruby-dist-master/lastBuild/api/xml'
  end

  it 'should detect broken build' do
    VCR.use_cassette('jenkins_broken') do
      server.jobs.should == {
        "woo" => {
          activity: :sleeping,
          last_build_status: :failure,
          last_build_time: 5597,
          url: "http://ci.jruby.org/job/jruby-dist-master/1926/",
          last_label: "1926"
        }
      }
    end
  end

  it 'should detect running build' do
    VCR.use_cassette('jenkins_building') do
      server.jobs.should == {
        "woo" => {
          activity: :building,
          last_build_status: :success,
          last_build_time: 5597,
          url: "http://ci.jruby.org/job/jruby-dist-master/1926/",
          last_label: "1926"
        }
      }
    end
  end

  it 'should detect successful build' do
    VCR.use_cassette('jenkins_successful') do
      server.jobs.should == {
        "woo" => {
          activity: :sleeping,
          last_build_status: :success,
          last_build_time: 5597,
          url: "http://ci.jruby.org/job/jruby-dist-master/1926/",
          last_label: "1926"
        }
      }
    end
  end
end
