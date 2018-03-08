require "influxdb"


username = 'valeriano'
password = 'asd.123'
database = 'test'
name     = 'foobar'


influxdb = InfluxDB::Client.new database, username: username, password: password

Value = (0...360).to_a.map {|i| Math.send(:sin, i / 10.0) * 10}.each

loop do
	data = {
		values: { value: Value.next, result: 'bla' },
		tags: { wave: 'sine' } 
	}
	influxdb.write_point(name, data)

	sleep 1
end
