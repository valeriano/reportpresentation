require 'nokogiri'
require 'open-uri'
require 'influxdb'

username        = ENV['wltp_adminuser']
password        = ENV['wltp_adminpass']
jenkins_user    = ENV['wltp_adminuser']
jenkins_pass    = ENV['wltp_adminpass']
database        = 'test'
name            = 'd'
time_precision  = 'ns'

influxdb = InfluxDB::Client.new database, 
  username: username, 
  password: password

#@doc = Nokogiri::XML(open('http://localhost:8080/job/Test/api/xml', :http_basic_authentication => [jenkins_user,jenkins_pass]))

for i in 137..155
 timestamp = 0

 for j in 1..29
    puts i.to_s + " - " + j.to_s
    if j == 17 or i.between?(141,148)
      next
    end
    @doc = Nokogiri::XML(File.read("../1/#{j}_#{i}.xml"))
  
    tests = @doc.xpath("//testsuite/@tests").text

    #puts "time: " + @doc.xpath("//testsuite/@time").text
    testtime = @doc.xpath("//testsuite/@time").text

    #puts "name: " + @doc.xpath("//testsuite/@name").text
    testname = @doc.xpath("//testsuite/@name").text

    #puts "categories: " + @doc.xpath("//property[@name = 'categories']/@value").text
    categories = @doc.xpath( "//property[@name = 'categories']/@value").text["PostInstallation"]
    if categories == nil
      categories=@doc.xpath( "//property[@name = 'categories']/@value").text["FunctionalTest"]
    end
    if categories == nil
      categories=@doc.xpath( "//property[@name = 'categories']/@value").text["PreInstallation"]
    end
    if categories == nil
      categories=@doc.xpath( "//property[@name = 'categories']/@value").text["RestCategory"]
      if categories != nil
        categories = "FunctionalTest"
      end
    end

    puts categories

    #puts "timestamp: " + @doc.xpath("//property[@name = 'timestamp']/@value").text
    if timestamp == 0
      timestamp = Integer(@doc.xpath("//property[@name = 'timestamp']/@value").text)
      timestamp = timestamp * 1000000
    end
    if timestamp != 0
      timestamp = timestamp + 1
    end
    puts timestamp

    #puts "errors: " + @doc.xpath("//testsuite/@errors").text
    errors = @doc.xpath("//testsuite/@errors").text

    #puts "failures: " + @doc.xpath("//testsuite/@failures").text
    failures = @doc.xpath("//testsuite/@failures").text

    data = {
      values: {
        value: i,
        tests: tests,
        testtime: testtime.to_f,
        testname: testname,
        errors: errors,
        failures: failures,
       },
       tags: {
        run: i,
        category: categories
       },
       timestamp: Integer(timestamp)
    }

    #puts data
    #influxdb.write_point(name,data,time_precision)
  end
end
