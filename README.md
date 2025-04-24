# How to access
Download the source codes from this repo as ZIP files and decompress them.

# Hardware dependencies
No specific hardware dependencies.

# Software dependencies
The tested OS for the scripts is Ubuntu 24.04. The required software packages are Docker and Docker Compose. The project also relies on creating EC2 instances in order to run and benchmark the sample projects' performance. 

# Data sets
No specific data sets needed to be installed 

# Models
No specific model needed to be installed 

# Installation
Copy the contents of the scripts respectively and paste them into the EC2 instances.
Grant the scripts the right to be executed by typing "chmod +x {name of the script}"
First, run the install_docker.sh to install Docker.
Then, run the script under the "deploy" folder to clone and deploy the sample projects.

# Experiment Flow
TBC

# Evaluation and Expected Results
Different EC2 instances have different optimal applications coupled with Docker to work with. 
Applications with a few file I/O operations and simple functionalities could perform better with smaller instances by having a smaller latency.
Applications with moderate complexity and possibly requiring multiple containers to operate would need larger instances to achieve better performance through having a larger number of reads and writes to the SQL database and smaller operation latency.
