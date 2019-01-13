# Author: Oliver Dawkins
# Read sensor measurements from Ti SensorTag attached to Intel Edison and post to IBM Cloud

# Import mraa library for IO communication
import mraa
# Import re library for handling REGEX operations
import re
# Import Timer and Date Time
from threading import Timer
import datetime
# Import libraries to post data to the cloud
import json
import requests
# Import library for configuration
import configparser
# Import Ordered Dictionary for ordering JSON payloads
from collections import OrderedDict

# Variables to handle UART serial communication between Edison and SensorTag
uart = mraa.Uart("/dev/ttyACM0")
uart.setBaudRate(115200)
#uart.setMode(8,mraa.UART_PARITY_NONE,1)
#uart.setFlowcontrol(False, False)

# Variable for expected number of sensors
numSensors = 6
# Variable for time interval between readings in seconds as a double
readingInterval = 60.0

# Variables for reading Envirosensor configuration file
config = configparser.ConfigParser()
config.read('/home/root/envirosensor.config')

# Variables for communicating with IBM Cloud
orgID = config['settings']['orgID']
deviceType = config['settings']['deviceType']
deviceID = config['settings']['deviceID']
authToken = config['settings']['authToken']
authMethod = 'use-token-auth'
eventType = config['settings']['eventType']
portNum = '8883'

requesturl = 'https://' + orgID + '.messaging.internetofthings.ibmcloud.com:' + portNum + '/api/v0002/device/types/' + deviceType + '/devices/' + deviceID + '/events/' + eventType

auth = (authMethod, authToken)
header = {'Content-Type': 'application/json'}

def postData(data):
    response = requests.post(requesturl, data=data, auth=auth, headers=header)

def accessSensorTag():
    flag = 0
    measurement = ""
    sensordata = {}

    # Start countdown to next sensor read
    Timer(readingInterval, accessSensorTag).start()

    print "Reading Sensor at " + str(datetime.datetime.now())
    while (len(sensordata) < numSensors):

        # Get byte and append
        data_byte = uart.readStr(1)
        print data_byte

        measurement = measurement + data_byte

        if(data_byte == "$" and flag == 0): # '$' indicates a new incoming measurement
        
            flag = 1
        elif (data_byte == "?" and flag == 1): # '?' indicates the end of measurement

            # There is a new mesurement. Clean it and print it!
            measurement = measurement.strip()
            measurement = re.sub('[$?!]', '', measurement)
            #print measurement

            # Store the new measurement into a dictionarry
            measurement_parts = measurement.split(":")
            sensordata[measurement_parts[0]] = measurement_parts[1]
            # print sensordata

            print "measurement added to sensor data"

            # Reset variables
            measurement = ""
            flag = 0

    #Timer(readingInterval, accessSensorTag).start()

    print sensordata

    # Prepare data upload to IBM Watson
    sensor_payload = sensordata
    print "Payload is " + str(sensor_payload)

    # Get data time stamp
    timeStamp = str(datetime.datetime.now())
    print "Sending data at to Watson at " + timeStamp

    # Use an ordered dictionary to create an ordered JSON payload
    data = json.dumps(OrderedDict([('DeviceID', deviceID), ('DeviceType', deviceType), ('Event', eventType), ('Time', timeStamp), ('Data', sensor_payload)]))
    print "Data posted to Watson is " + str(data)

    # Call Watson URL and send data
    response = postData(data)

    # print str(response.text)
    # print str(response.content)
    # print "Response Code: " + str(response.status_code) + " Response Reason = " + str(response.reason)

accessSensorTag()
