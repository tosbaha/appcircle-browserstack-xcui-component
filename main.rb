# frozen_string_literal: true

require 'English'
require 'net/http'
require 'json'

BROWSERSTACK_DOMAIN                = 'https://api-cloud.browserstack.com'
APP_UPLOAD_ENDPOINT                = '/app-automate/xcuitest/v2/app'
TEST_SUITE_UPLOAD_ENDPOINT         = '/app-automate/xcuitest/v2/test-suite'
APP_AUTOMATE_BUILD_ENDPOINT        = '/app-automate/xcuitest/v2/build'
APP_AUTOMATE_BUILD_STATUS_ENDPOINT = '/app-automate/xcuitest/v2/builds/'

def env_has_key(key)
  !ENV[key].nil? && ENV[key] != '' ? ENV[key] : abort("Missing #{key}.")
end

def run_command(cmd)
  puts "@@[command] #{cmd}"
  output = `#{cmd}`
  raise 'Command failed' unless $CHILD_STATUS.success?

  output
end

def upload(file, endpoint, username, access_key)
  uri = URI.parse("#{BROWSERSTACK_DOMAIN}#{endpoint}")
  req = Net::HTTP::Post.new(uri.request_uri)
  req.basic_auth(username, access_key)
  form_data = [['file', File.open(file)]]
  req.set_form(form_data, 'multipart/form-data')
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  JSON.parse(res.body, symbolize_names: true)
end

def post(payload, endpoint, username, access_key)
  uri = URI.parse("#{BROWSERSTACK_DOMAIN}#{endpoint}")
  req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
  req.body = payload
  req.basic_auth(username, access_key)
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  JSON.parse(res.body, symbolize_names: true)
end

def build(payload, app_url, test_suite_url, username, access_key)
  payload = payload.sub('AC_BROWSERSTACK_APP_URL', app_url)
  payload = payload.sub('AC_BROWSERSTACK_TEST_URL', test_suite_url)
  result = post(payload, APP_AUTOMATE_BUILD_ENDPOINT, username, access_key)
  if result[:message] == 'Success'
    puts 'Build started successfully'
    result[:build_id]
  else
    puts 'Build failed'
    exit 1
  end
end

def check_status(build_id, test_timeout, username, access_key)
  if test_timeout <= 0
    puts('Plan timed out')
    exit(1)
  end
  uri = URI.parse("#{BROWSERSTACK_DOMAIN}#{APP_AUTOMATE_BUILD_STATUS_ENDPOINT}#{build_id}")

  req = Net::HTTP::Get.new(uri.request_uri,
                           { 'Content-Type' => 'application/json' })
  req.basic_auth(username, access_key)

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  case res
  when Net::HTTPClientError, Net::HTTPServerError
    abort "\nError checking status: #{res.code} (#{res.message})\n\n"
  end
  response = JSON.parse(res.body, symbolize_names: true)
  status = response[:status]
  if status != 'running' && status != ''
    puts('Execution finished')
    if status == 'failed'
      puts('Test plan failed')
      exit(1)
    end
  else
    puts('Test plan is still running...')
    STDOUT.flush
    sleep(10)
    check_status(build_id, test_timeout - 10, username, access_key)
    true
  end
end

runner_app = env_has_key('AC_UITESTS_RUNNER_PATH')
ipa_path = env_has_key('AC_TEST_IPA_PATH')
tmp_folder = env_has_key('AC_TEMP_DIR')
runner_zip = "#{tmp_folder}/test_runner.zip"

Dir.chdir(File.dirname(runner_app)) do
  run_command("zip -r -D  #{runner_zip} #{File.basename(runner_app)}")
end

username = env_has_key('AC_BROWSERSTACK_USERNAME')
access_key = env_has_key('AC_BROWSERSTACK_ACCESS_KEY')
test_timeout = env_has_key('AC_BROWSERSTACK_TIMEOUT').to_i
payload = env_has_key('AC_BROWSERSTACK_PAYLOAD')

puts "Uploading IPA #{ipa_path}"
STDOUT.flush
app_url = upload(ipa_path, APP_UPLOAD_ENDPOINT, username, access_key)[:app_url]
puts "App uploaded. #{app_url}"
puts "Uploading Test Runner #{runner_zip}"
STDOUT.flush
test_suite_url = upload(runner_zip, TEST_SUITE_UPLOAD_ENDPOINT, username, access_key)[:test_suite_url]
puts "Test uploaded. #{test_suite_url}"
puts 'Starting a build'
STDOUT.flush
build_id = build(payload, app_url, test_suite_url, username, access_key)
check_status(build_id, test_timeout, username, access_key)
