# How to access
* Download the source codes from this repo as ZIP files and decompress them.

# Hardware dependencies
* No specific hardware dependencies.

# Software dependencies
* The tested OS for the scripts is Ubuntu 24.04.
* The required software packages are Docker and Docker Compose.
*  The project also relies on creating EC2 instances in order to run and benchmark the sample projects' performance. 

# Data sets
* No specific data sets needed to be installed 

# Models
* No specific model needed to be installed 

# Installation
1. Copy the contents of the scripts respectively and paste them into the EC2 instances.
2. Grant the scripts the right to be executed by typing "chmod +x {name of the script}"
3. Run the install_docker.sh to install Docker.
4. Run the scripts under one of the "deploy" folders to clone and deploy the sample projects.

# Experiment Flow
* For benchmarking the instances while running the tweet app with Docker:
1. Run deploy_tweet_app.sh with "sudo ./deploy_tweet_app.sh".
2. Wait for the deployment to be completed.
3. Copy the IP address (with the port number) shown in the terminal once the deployment is completed.
4. Open Chrome or a browser
5. Paste and traverse to the IP address
6. Run tweet_app_benchmark.sh with "sudo ./tweet_app_benchmark.sh" to test for 5 minutes or Run deploy_tweet_app_short.sh with "sudo ./tweet_app_benchmark_short.sh" to test for 1 minute.
7. Observe the metrics shown in the terminal once the benchmarking is completed.

* For benchmarking the instances while running the tweet app with Docker:
1. Run deploy_tweet_app.sh with "sudo ./deploy_voting_app.sh".
2. Wait for the deployment to be completed.
3. Copy the IP address of the EC2 instance and remember the port number shown in the terminal once the deployment is completed.
4. Open Chrome or a browser
5. Paste and traverse to the IP address with two different port numbers (8080 is for the voting UI and 8011 is for the results UI)
6. Run voting_app_benchmark.sh with "sudo ./voting_app_benchmark.sh" to test for 5 minutes or Run voting_app_benchmark_short.sh with "sudo ./voting_app_benchmark_short.sh" to test for 1 minute.
7. Observe the metrics shown in the terminal once the benchmarking is completed.
   
# Evaluation and Expected Results
* Different EC2 instances have different optimal applications coupled with Docker to work with. 
* Applications with a few file I/O operations and simple functionalities could perform better with smaller instances by having a smaller latency.
* Applications with moderate complexity and possibly requiring multiple containers to operate would need larger instances to achieve better performance, as seen from the larger number of reads and writes to the SQL database and smaller operation latency.
