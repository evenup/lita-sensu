require "spec_helper"

describe Lita::Handlers::Sensu, lita_handler: true do

  it { is_expected.to route_command('sensu client test1').to(:client) }
  it { is_expected.to route_command('sensu client test1 history').to(:client_history) }
  it { is_expected.to route_command('sensu clients').to(:clients) }
  it { is_expected.to route_command('sensu events').to(:events) }
  it { is_expected.to route_command('sensu events for test1').to(:events) }
  it { is_expected.to route_command('sensu info').to(:info) }
  it { is_expected.to route_command('sensu remove client test1').to(:remove_client) }
  it { is_expected.to route_command('remove client test1').to(:remove_client) }
  it { is_expected.to route_command('sensu resolve event test1/check2').to(:resolve) }
  it { is_expected.to route_command('resolve event test1/check2').to(:resolve) }
  it { is_expected.to route_command('resolve event test1/check2').to(:resolve) }
  it { is_expected.to route_command('sensu silence test1').to(:silence) }
  it { is_expected.to route_command('silence test1').to(:silence) }
  it { is_expected.to route_command('sensu silence test1 check2').to(:silence) }
  it { is_expected.to route_command('sensu silence test1/check2').to(:silence) }
  it { is_expected.to route_command('sensu stashes').to(:stashes) }

  let(:response) { double("Faraday::Response") }

  before do
    registry.config.handlers.sensu.api_url = 'http://sensu.example.com'
    registry.config.handlers.sensu.api_port = 5678
    registry.config.handlers.sensu.domain = 'example.com'
  end

  describe '#client' do
    client_response = '{"subscriptions":["apache","all"],"name":"test1.example.com","address":"172.31.64.55","bind":"127.0.0.1","safe_mode":false,"keepalive":{},"version":"0.14.0","timestamp":1427859223}'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/clients/test1.example.com').and_return(response)
    end

    it 'should fetch client info' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(client_response)
      send_message('sensu client test1.example.com')
      expect(replies.last).to eq("{\n  \"subscriptions\": [\n    \"apache\",\n    \"all\"\n  ],\n  \"name\": \"test1.example.com\",\n  \"address\": \"172.31.64.55\",\n  \"bind\": \"127.0.0.1\",\n  \"safe_mode\": false,\n  \"keepalive\": {\n  },\n  \"version\": \"0.14.0\",\n  \"timestamp\": 1427859223\n}")
    end

    it 'should fetch client info appending domain name' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(client_response)
      send_message('sensu client test1')
      expect(replies.last).to eq("{\n  \"subscriptions\": [\n    \"apache\",\n    \"all\"\n  ],\n  \"name\": \"test1.example.com\",\n  \"address\": \"172.31.64.55\",\n  \"bind\": \"127.0.0.1\",\n  \"safe_mode\": false,\n  \"keepalive\": {\n  },\n  \"version\": \"0.14.0\",\n  \"timestamp\": 1427859223\n}")
    end

    it 'should handle client not found' do
      allow(response).to receive(:status).and_return(404)
      send_message('sensu client test1')
      expect(replies.last).to eq('test1.example.com was not found')
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu client test1')
      expect(replies.last).to eq('An error occurred fetching client test1.example.com')
    end
  end #client

  describe '#client_history' do
    history_response = '[{"check":"postfix-running","history":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"last_execution":1427885448,"last_status":0},{"check":"postfix-mailq","history":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"last_execution":1427885448,"last_status":0},{"check":"disk-metrics","history":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"last_execution":1427885481,"last_status":0},{"check":"puppet-last_run","history":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"last_execution":1427884845,"last_status":0},{"check":"keepalive","history":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"last_execution":1427885501,"last_status":0}]'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/clients/test1.example.com/history').and_return(response)
    end

    it 'should fetch client info' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(history_response)
      send_message('sensu client test1.example.com history')
      expect(replies.last).to eq("disk-metrics: status - 0; last checked - 2015-04-01 04:51:21 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\nkeepalive: status - 0; last checked - 2015-04-01 04:51:41 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npostfix-mailq: status - 0; last checked - 2015-04-01 04:50:48 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npostfix-running: status - 0; last checked - 2015-04-01 04:50:48 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npuppet-last_run: status - 0; last checked - 2015-04-01 04:40:45 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n")
    end

    it 'should fetch client info appending domain name' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(history_response)
      send_message('sensu client test1 history')
      expect(replies.last).to eq("disk-metrics: status - 0; last checked - 2015-04-01 04:51:21 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\nkeepalive: status - 0; last checked - 2015-04-01 04:51:41 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npostfix-mailq: status - 0; last checked - 2015-04-01 04:50:48 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npostfix-running: status - 0; last checked - 2015-04-01 04:50:48 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\npuppet-last_run: status - 0; last checked - 2015-04-01 04:40:45 -0600; history - 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu client test1 history')
      expect(replies.last).to eq('An error occurred fetching client test1.example.com history')
    end
  end #client_history

  describe '#clients' do
    clients_response = '[{"subscriptions":["tomcat","all"],"name":"test2.example.com","safe_mode":false,"address":"172.31.0.2","bind":"127.0.0.1","keepalive":{},"version":"0.14.0","timestamp":1427887539},{"subscriptions":["apache","all"],"keepalive":{},"name":"test1.example.com","safe_mode":false,"address":"172.31.0.1","bind":"127.0.0.1","version":"0.14.0","timestamp":1427887548}]'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/clients').and_return(response)
    end

    it 'should list all clients' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(clients_response)
      send_message('sensu clients')
      expect(replies.last).to eq("test1.example.com (172.31.0.1) subscriptions: all, apache\ntest2.example.com (172.31.0.2) subscriptions: all, tomcat\n")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu clients')
      expect(replies.last).to eq('An error occurred fetching clients')
    end
  end #clients

  describe '#events' do
    events_response = '[{"id":"a622267d-88bf-4eea-9455-ec8f001ca916","client":{"bind":"127.0.0.1","safe_mode":false,"name":"test1.example.com","subscriptions":["provisioner","all","apache"],"keepalive":{},"address":"172.31.0.1","version":"0.14.0","timestamp":1416007406},"check":{"command":"/etc/sensu/plugins/check-procs.rb -p /usr/sbin/pdns_server -w 2 -c 2 -W 2 -C 1","subscribers":[""],"handlers":["default"],"standalone":true,"interval":60,"name":"pdns-server-running","issued":1416007420,"executed":1416007420,"duration":2.107,"output":"CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_server/\\n","status":2,"history":["0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","2","2","2"]},"occurrences":3,"action":"create"},{"id":"4b107db0-f7be-4dc3-a5ba-76a5b9dba4dd","client":{"bind":"127.0.0.1","safe_mode":false,"name":"test2.example.com","subscriptions":["provisioner","all","apache"],"keepalive":{},"address":"172.31.0.2","version":"0.14.0","timestamp":1416007406},"check":{"subscribers":[""],"handlers":["default"],"command":"/etc/sensu/plugins/check-procs.rb -p /usr/sbin/pdns_puppetdb -w 25 -c 30 -C 1","interval":600,"standalone":true,"name":"pdns_puppetdb_running","issued":1416007418,"executed":1416007418,"duration":1.507,"output":"CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_puppetdb/\\n","status":2,"history":["0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","2"]},"occurrences":1,"action":"create"}]'
    test1_events_response = '[{"id":"a622267d-88bf-4eea-9455-ec8f001ca916","client":{"bind":"127.0.0.1","safe_mode":false,"name":"test1.example.com","subscriptions":["provisioner","all","apache"],"keepalive":{},"address":"172.31.0.1","version":"0.14.0","timestamp":1416007406},"check":{"command":"/etc/sensu/plugins/check-procs.rb -p /usr/sbin/pdns_server -w 2 -c 2 -W 2 -C 1","subscribers":[""],"handlers":["default"],"standalone":true,"interval":60,"name":"pdns-server-running","issued":1416007420,"executed":1416007420,"duration":2.107,"output":"CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_server/\\n","status":2,"history":["0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","2","2","2"]},"occurrences":3,"action":"create"}]'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/events').and_return(response)
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/events/test1.example.com').and_return(response)
    end

    it 'should list all events' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(events_response)
      send_message('sensu events')
      expect(replies.last).to eq("test1.example.com (pdns-server-running) - CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_server/\ntest2.example.com (pdns_puppetdb_running) - CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_puppetdb/\n")
    end

    it 'should list all events for a specific client' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(test1_events_response)
      send_message('sensu events for test1')
      expect(replies.last).to eq("test1.example.com (pdns-server-running) - CheckProcs CRITICAL: Found 0 matching processes; cmd //usr/sbin/pdns_server/\n")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu events for test1')
      expect(replies.last).to eq('An error occurred fetching clients')
    end
  end #events

  describe '#info' do
    info_response = '{"sensu":{"version":"0.14.0"},"transport":{"keepalives":{"messages":0,"consumers":1},"results":{"messages":0,"consumers":1},"connected":true},"redis":{"connected":true}}'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/info').and_return(response)
    end

    it 'should return api info' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(info_response)
      send_message('sensu info')
      expect(replies.last).to eq("{\n  \"sensu\": {\n    \"version\": \"0.14.0\"\n  },\n  \"transport\": {\n    \"keepalives\": {\n      \"messages\": 0,\n      \"consumers\": 1\n    },\n    \"results\": {\n      \"messages\": 0,\n      \"consumers\": 1\n    },\n    \"connected\": true\n  },\n  \"redis\": {\n    \"connected\": true\n  }\n}")
    end
  end #info

  describe '#remove_client' do
    remove_response = '[{"subscriptions":["tomcat","all"],"name":"test2.example.com","safe_mode":false,"address":"172.31.0.2","bind":"127.0.0.1","keepalive":{},"version":"0.14.0","timestamp":1427887539},{"subscriptions":["apache","all"],"keepalive":{},"name":"test1.example.com","safe_mode":false,"address":"172.31.0.1","bind":"127.0.0.1","version":"0.14.0","timestamp":1427887548}]'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:delete).with('http://sensu.example.com:5678/clients/test1.example.com').and_return(response)
    end

    it 'should remove a client' do
      allow(response).to receive(:status).and_return(202)
      allow(response).to receive(:body).and_return(remove_response)
      send_message('sensu remove client test1')
      expect(replies.last).to eq("test1.example.com removed")
    end

    it 'should handle 404' do
      allow(response).to receive(:status).and_return(404)
      send_message('sensu remove client test1')
      expect(replies.last).to eq("test1.example.com was not found")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu remove client test1')
      expect(replies.last).to eq('An error occurred removing test1.example.com')
    end
  end #remove_client

  describe '#resolve' do
    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/resolve', '{"client":"test1.example.com","check":"pdns-server-running"}').and_return(response)
    end

    it 'should resolve an event' do
      allow(response).to receive(:status).and_return(202)
      send_message('sensu resolve event test1/pdns-server-running')
      expect(replies.last).to eq("test1.example.com/pdns-server-running resolved")
    end

    it 'should handle malformed messages' do
      allow(response).to receive(:status).and_return(400)
      send_message('sensu resolve event test1/pdns-server-running')
      expect(replies.last).to eq("Resolve message was malformed: {\"client\":\"test1.example.com\",\"check\":\"pdns-server-running\"}")
    end

    it 'should handle 404' do
      allow(response).to receive(:status).and_return(404)
      send_message('sensu resolve event test1/pdns-server-running')
      expect(replies.last).to eq("test1.example.com/pdns-server-running was not found")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu resolve event test1/pdns-server-running')
      expect(replies.last).to eq('There was an error resolving test1.example.com/pdns-server-running')
    end
  end #resolve

  describe '#silence' do
    it 'should silence an event on a specific client' do
      allow_any_instance_of(Faraday::Connection).to receive(:post).with("http://sensu.example.com:5678/silenced", '{"creator":"Test User","expire":3600,"reason":"Because Lita says so!","subscription":"client:test1.example.com","check":"disk-free"}').and_return(response)
      allow(response).to receive(:status).and_return(201)
      send_message('sensu silence test1/disk-free')
      expect(replies.last).to eq("test1.example.com:disk-free silenced for 1h")
    end

   it 'should silence for seconds' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":1,"reason":"Because Lita says so!","subscription":"client:test1.example.com","check":"disk-free"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1/disk-free for 1s')
     expect(replies.last).to eq("test1.example.com:disk-free silenced for 1s")
   end

   it 'should silence a client' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":3600,"reason":"Because Lita says so!","subscription":"client:test1.example.com"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1')
     expect(replies.last).to eq("test1.example.com:* silenced for 1h")
   end

   it 'should silence for minutes' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":60,"reason":"Because Lita says so!","subscription":"client:test1.example.com"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1 for 1m')
     expect(replies.last).to eq("test1.example.com:* silenced for 1m")
   end

   it 'should silence for hours' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":3600,"reason":"Because Lita says so!","subscription":"client:test1.example.com"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1 for 1h')
     expect(replies.last).to eq("test1.example.com:* silenced for 1h")
   end

   it 'should silence for days' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":86400,"reason":"Because Lita says so!","subscription":"client:test1.example.com"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1 for 1d')
     expect(replies.last).to eq('test1.example.com:* silenced for 1d')
   end

   it 'should provide feedback for invalid duration' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/stashes', '{"content":{"by":"Test User"},"expire":3600,"path":"silence/test1.example.com"}').and_return(response)
     allow(response).to receive(:status).and_return(201)
     send_message('sensu silence test1 for 1z')
     expect(replies.last).to eq("Unknown unit (z).  I know s (seconds), m (minutes), h (hours), and d(days)")
   end

   it 'should handle internal sensu errors' do
     allow_any_instance_of(Faraday::Connection).to receive(:post).with('http://sensu.example.com:5678/silenced', '{"creator":"Test User","expire":3600,"reason":"Because Lita says so!","subscription":"client:test1.example.com","check":"disk-free"}').and_return(response)
     allow(response).to receive(:status).and_return(500)
     expect(Lita.logger).to receive(:warn).with(/internal error/)
     send_message('sensu silence test1/disk-free')
     expect(replies.last).to eq('An error occurred silencing to test1.example.com:disk-free')
   end
  end #silence

  describe '#stashes' do
    stashes_response = '[{"path":"silence/test1.example.com/disk-free","content":{"timestamp":1383441836},"expire":3600}]'

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get).with('http://sensu.example.com:5678/stashes').and_return(response)
    end

    it 'should list all clients' do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(stashes_response)
      send_message('sensu stashes')
      expect(replies.last).to eq("silence/test1.example.com/disk-free added on 2013-11-02 19:23:56 -0600 expires in 3600 seconds\n")
    end

    it 'should handle internal sensu errors' do
      allow(response).to receive(:status).and_return(500)
      expect(Lita.logger).to receive(:warn).with(/internal error/)
      send_message('sensu stashes')
      expect(replies.last).to eq('An error occurred fetching stashes')
    end
  end #stashes

end
