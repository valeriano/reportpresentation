require 'nokogiri'
require 'open-uri'
require 'influxdb'

username        = ENV['wltp_adminuser']
password        = ENV['wltp_adminpass']
jenkins_user    = ENV['wltp_adminuser']
jenkins_pass    = ENV['wltp_adminpass']
database        = 'test'
singlestats     = 'd'
fullstats       = 'e'
time_precision  = 'ns'

influxdb = InfluxDB::Client.new database, 
  username: username, 
  password: password

#@doc = Nokogiri::XML(open('http://localhost:8080/job/Test/api/xml', :http_basic_authentication => [jenkins_user,jenkins_pass]))

for i in 137..155
 if i.between?(141,148)
   next
 end

 stats = Hash.new
 timestamp = 0
 
 cat = ""
 totaltime = 0
 totalfailures = 0
 totaltests = 0
  
 for j in 1..29
    #puts i.to_s + " - " + j.to_s
    if j == 17
      next
    end
    @doc = Nokogiri::XML(File.read("../1/#{j}_#{i}.xml"))
  

    #puts "time: " + @doc.xpath("//testsuite/@time").text
    testtime = @doc.xpath("//testsuite/@time").text
    totaltime = totaltime + testtime.to_f()

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

    if cat != categories
      cat = categories
      totaltests = 0
      totaltime = 0
      totalfailures = 0
    end
    #puts categories

    #puts "timestamp: " + @doc.xpath("//property[@name = 'timestamp']/@value").text
    if timestamp == 0
      timestamp = Integer(@doc.xpath("//property[@name = 'timestamp']/@value").text)
      timestamp = timestamp * 1000000
    end
    if timestamp != 0
      timestamp = timestamp + 1
    end
    #puts timestamp
    
    tests = @doc.xpath("//testsuite/@tests").text
    totaltests = totaltests + Integer(tests)

    #puts "errors: " + @doc.xpath("//testsuite/@errors").text
    errors = @doc.xpath("//testsuite/@errors").text

    #puts "failures: " + @doc.xpath("//testsuite/@failures").text
    failures = @doc.xpath("//testsuite/@failures").text
    totalfailures = totalfailures + Integer(failures)
    stats[categories] = {"totaltime" => 0, "totalfailures" => 0, "totaltests" => 0}

    stats[categories]["totaltime"]=totaltime
    stats[categories]["totalfailures"]=totalfailures
    stats[categories]["totaltests"] = totaltests

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

    puts data
    #influxdb.write_point(singlestats,data,time_precision)
  end
  poststats = {
    values: {
      total: stats["PostInstallation"]["totaltests"],
      failures: stats["PostInstallation"]["totalfailures"],
      testtime: stats["PostInstallation"]["totaltime"]
    },
    tags: {
      run: i,
      category: "PostInstallation"
    },
    timestamp: timestamp
  }
  functionalstats = {
    values: {
      total: stats["FunctionalTest"]["totaltests"],
      failures: stats["FunctionalTest"]["totalfailures"],
      testtime: stats["FunctionalTest"]["totaltime"]
    },
    tags: {
      run: i,
      category: "FunctionalTest"
    },
    timestamp: timestamp
  }

  puts poststats
  puts functionalstats
  #influxdb.write_point(fullstats,poststats,time_precision)
  #influxdb.write_point(fullstats,functionalstats,time_precision)
end
