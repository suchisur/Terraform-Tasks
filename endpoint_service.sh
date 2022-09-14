interval=3 #Intervals in seconds in which health checks have to be performed
healthy_threshold=4 #Minimum number of consecutive times status should be healthy so that endpoint is declared as healthy
unhealthy_threshold=2 #Minimum number of consecutive times status needs to be unhealtnhy to be declared as unhealthy
status_code=0 #status code check
healthy=0 # count of healthy checks
unhealthy=0 # count of unhealthy checks
alert_time_seconds=10 # frequency of sending alerts in seconds
time_start=$(date +%s) #start time to measure start point of sending an alert
connection_timeout=0.02 #connection timout in seconds
endpoint="https://google.com" #endpoint to be monitored
MESSAGE="The endpoint $endpoint is down. Please check for possible causes" #alert which has to be sent to the team 
TO=<team email id as a string>
SendMail(){
	echo $MESSAGE | sudo ssmtp -vvv $TO
}

GetHealth(){

		while true
		do
			code=$(curl --connect-timeout $connection_timeout -o /dev/null -s -w "%{http_code}\n" -X GET -L $endpoint)
			echo $code
			status_code=$(($code/100))
			#echo $status_code
			if [ $status_code == 2 ]
			then 
				healthy=$(($healthy+1))
				#echo $healthy
				unhealthy=0
				if [ $healthy == $healthy_threshold ]
				then 
					echo "Healthy"
					sleep $interval
					healthy=0
				fi
			else 
				unhealthy=$(($unhealthy+1))
				#echo $unhealthy
				healthy=0
				if [ $unhealthy == $unhealthy_threshold ]
				then
					echo "Unhealthy"
					sleep $interval
					time_now=$(date +%s)
					seconds_passed=$(($time_now-$time_start))
					if [ $seconds_passed -ge $alert_time_seconds ]
					then
						echo "Alert Email"
						#SMTP Code
						SendMail
						time_start=$(date +%s)
					else
						echo "waiting for alert"
					fi

					unhealthy=0
				fi
			fi
		done
}

GetHealth
