WRITEKEY="<insert key here>"
PIN = 4 
sleep_time=30*60000 
client_ip="192.168.1.129"
client_netmask="255.255.255.0"
client_gateway="192.168.1.1"

--
-- init functions
--

function readDHT()
    status,temp,humi,temp_decimial,humi_decimial = dht.read(PIN)
    temp_f = temp*1.8+32
    if( status == dht.OK ) then
      print("DHT Temperature(F):"..temp_f..";".."Humidity:"..humi)
    else
      humi=0
      temp=0
      temp_f=0
        if( status == dht.ERROR_CHECKSUM ) then
            print( "DHT Checksum error." );
        elseif( status == dht.ERROR_TIMEOUT ) then
            print( "DHT Time out." );
        end
    end
end

function sendTS(humi,temp_f,status)
conn = nil
conn = net.createConnection(net.TCP, 0)
conn:on("receive",
    function(conn, payload)
    conn:close()
    print(payload)
    end)
conn:on("connection",
    function(conn, payload)
    print("Connected")
    conn:send('GET /update?key='..WRITEKEY..
    '&field1='..temp_f..
    '&field2='..humi..
   '&field3='..status..
    'HTTP/1.1\r\n\Host: api.thingspeak.com\r\nAccept: */*\r\nUser-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n\r\n')
    end)
conn:on("disconnection",
    function(conn, payload)
    print("Disconnected")
    onDsConn()
    end)
conn:connect(80,'api.thingspeak.com')
conn:close()
end

function onDsConn ()
  print("Disconnect finished")
  wifi.sta.disconnect()
end


--
--main
--
function theLoop()
  wifi.sta.disconnect() --read DHT&ADC data without WIFI noise

  readDHT()
  tmr.delay(2000000) --wait 2 seconds
  readDHT()
  wifi.setmode(wifi.STATION)
  wifi.sta.config("<wifi sid here>","<passwordHere>") --now connect AP
  if client_ip ~= "" then
    wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
  end

  tmr.alarm(1, 1000, 1, function()
  ip = wifi.sta.getip()
  print("!!! wifi status")
  print(ip)
  if ip ~= nil then --wait for proper IP
        tmr.stop(1)
        sendTS(humi,temp_f,status)
    end
  end)
end

--Fire once immediately
tmr.alarm(0, 1000, tmr.ALARM_SINGLE, function() theLoop() end)
--Rinse and Repeat
tmr.alarm(2, sleep_time, tmr.ALARM_AUTO, function() theLoop() end)

