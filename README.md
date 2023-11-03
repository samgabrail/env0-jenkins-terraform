# Overview

Demo for Env0 to show how to use Jenkins with Terraform in Docker for IaC

## Jenkins

Let's take a look at how to install Jenkins on a Docker container.

### Create the Docker Container

Below is the Dockerfile for the Jenkins container. Notice how we are installing the Terraform binary along with Ansible.

```shell
FROM jenkins/jenkins:lts

# Define arguments for Terraform and Ansible versions
ARG TF_VERSION=1.5.5
ARG ANSIBLE_VERSION=8.5.0

USER root

# Install necessary tools like wget and unzip before downloading Terraform
RUN apt-get update && \
    apt-get install -y wget unzip python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Use the TF_VERSION argument to download and install the specified version of Terraform
RUN wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin && \
    rm terraform_${TF_VERSION}_linux_amd64.zip

# Create a virtual environment for Python and activate it
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Use the ANSIBLE_VERSION argument to install the specified version of Ansible within the virtual environment
RUN pip install --upgrade pip cffi && \
    pip install ansible==${ANSIBLE_VERSION} && \
    pip install mitogen ansible-lint jmespath && \
    pip install --upgrade pywinrm

# Drop back to the regular jenkins user - good practice
USER jenkins
```

### Build the Docker Image

Now we can build the docker image using the following command:

```shell
docker build -t samgabrail/jenkins-terraform-docker .
```

### Run Docker Container

Now we can run the docker container using the following command:

```shell
docker run --name jenkins-terraform -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 samgabrail/jenkins-terraform-docker:latest
```

### Configure Jenkins

Once the container is running, we can access the Jenkins UI at http://localhost:8080.

Notice that a password has been written to the log and inside our container at this location:

`/var/jenkins_home/secrets/initialAdminPassword`

You can access this password inside our container by running this command:

```shell
docker exec -it jenkins-terraform cat /var/jenkins_home/secrets/initialAdminPassword
```

Install the suggested plugins

Then go ahead and create a first admin user

Next, keep the Jenkins URL as is which should be `http://localhost:8080` then save and finish the setup.

### Create a Jenkins Job

From the main Jenkins page, click on the `New Item` button. Then give it a name and select the Pipeline project type.

## Configure Terraform

Now that we have Jenkins running, we can configure Terraform.

## Configure Azure

Follow the guide [Azure Provider: Authenticating using a Service Principal with a Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal-in-the-azure-portal) to create an application and service principal.

## Jenkins Credentials

We now need to add the Azure credentials and the private key and username for Ansible to access the generated VM.



### Store Jenkins Data

You can store your entire jenkins data from the container somewhere on your local computer (don't check into git).

Then when rebuilding the Jenkins machine, copy the directory over using the following command:

```shell
scp -r jenkins_data/ adminuser@samg-jenkins.centralus.cloudapp.azure.com:/home/adminuser/
```

**Remember to restart the docker container**