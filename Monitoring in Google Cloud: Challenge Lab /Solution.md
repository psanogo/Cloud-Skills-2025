### Run the following Commands in CloudShell

```
curl -LO https://raw.githubusercontent.com/chayandeokar/Cloud-Skills-2025/refs/heads/master/Monitoring%20in%20Google%20Cloud%3A%20Challenge%20Lab%20/ARC115.sh
sudo chmod +x ARC115.sh
./ARC115.sh
```
* Go to `Create log-based metric` from [here](https://console.cloud.google.com/logs/metrics/edit?)

1. For Log-based metric name: enter `drabhi`

2. Paste The Following in `Build filter` & Replace PROJECT_ID
```
resource.type="gce_instance"
logName="projects/PROJECT_ID/logs/apache-access"
textPayload:"200"
```

3. Paste The Following in `Regular Expression` field:
```
execution took (\d+)

```
### Congratulations !!!!
