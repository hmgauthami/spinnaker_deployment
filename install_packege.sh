#!/bin/bash

# Make the build fail on errors.
set -e

# Strip the first part to avoid credentials leaks.
echo "repository=$(echo $repository | sed s/^.*@//g)"
echo "package_type=$package_type"
echo "packages=$packages"
echo "upgrade=$upgrade"

# Strip leading/trailing quotes if present.
repository=`echo $repository | sed 's/^"\(.*\)"$/\1/'`

# Strip leading/trailing quotes if present.
# Also convert a comma-separated list to a whitespace-separated one.
packages=`echo $packages | sed 's/^"\(.*\)"$/\1/' | sed 's/,/ /g'`


function provision_deb() {
  # https://www.packer.io/docs/builders/amazon-chroot.html look at gotchas at the end.
  if [[ "$disable_services" == "true" ]]; then
    echo "creating /usr/sbin/policy-rc.d to prevent services from being started"
    echo '#!/bin/sh' | sudo tee /usr/sbin/policy-rc.d > /dev/null
    echo 'exit 101' | sudo tee -a /usr/sbin/policy-rc.d > /dev/null
    sudo chmod a+x /usr/sbin/policy-rc.d
  fi

  if [[ "$repository" != "" ]]; then
    IFS=';' read -ra repo <<< "$repository"
    for i in "${repo[@]}"; do
      echo "deb $i" | sudo tee -a /etc/apt/sources.list.d/spinnaker.list > /dev/null
    done
  fi
  sudo apt-get update
  if [[ "$upgrade" == "true" ]]; then
    sudo unattended-upgrade -v
  fi
ls -lrt
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer
sudo apt-get install oracle-java8-set-default
sudo apt-get install --force-yes -y oracle-java8-unlimited-jce-policy
sudo apt-get install -y libjna-java
echo deb https://dl.bintray.com/sbt/debian / | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get update
sudo apt-get install sbt
sudo apt-get install apt-transport-https
echo \deb https://apt.datadoghq.com/ stable main\ | sudo tee -a /etc/apt/sources.list.d/datadog.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52
sudo apt-get update
sudo apt-get install -y datadog-agent
#sudo sh -c \sed 's/api_key:.*/api_key: a1cf359e6028f9dfa83fce34ae0f2a60/' /etc/dd-agent/datadog.conf.example > /etc/dd-agent/datadog.conf\
sudo apt-get install -y python.pip
aws s3 cp s3://m6builds/modeler-gy-portal_1.0-SNAPSHOT_all.deb /home/ubuntu/
sudo dpkg -i /home/ubuntu/modeler-gy-portal_1.0-SNAPSHOT_all.deb
sudo sed -i 's/portal.port=9000/portal.port=9443/' /etc/modeler-gy-portal/application.conf
sudo service modeler-gy-portal restart


#sudo sh -c \sed 's/api_key:.*/api_key: a1cf359e6028f9dfa83fce34ae0f2a60/' /etc/dd-agent/datadog.conf.example > /etc/dd-agent/datadog.conf\
  # Enforce the package installation order.
#  echo $packages
#  servicepack=${packages%=*}
#  echo $servicepack
#  pwd
#  sudo "/opt/rosco/config/packer/install_packages_$servicepack.sh"
  for package in $packages; do sudo apt-get install --force-yes -y $package; done

  # https://www.packer.io/docs/builders/amazon-chroot.html look at gotchas at the end.
  if [[ "$disable_services" == "true" ]]; then
    echo "removing /usr/sbin/policy-rc.d"
    sudo rm -f /usr/sbin/policy-rc.d
  fi

  if [[ "$repository" != "" ]]; then
    # Cleanup repository configuration
    sudo rm /etc/apt/sources.list.d/spinnaker.list
  fi
}

function provision_rpm() {
  if [[ "$repository" != "" ]]; then
    cat > /tmp/spinnaker.repo <<EOF
[spinnaker]
name=spinnaker
baseurl=$repository
gpgcheck=0
enabled=1
EOF
    sudo mv /tmp/spinnaker.repo /etc/yum.repos.d/
  fi

  if [[ "$upgrade" == "true" ]]; then
    sudo yum -y update
  fi

  # Enforce the package installation order.
  for package in $packages; do sudo yum -y install $package; done

  if [[ "$repository" != "" ]]; then
    # Cleanup repository configuration
    sudo rm /etc/yum.repos.d/spinnaker.repo
  fi
}

function main() {
  if [[ "$package_type" == "deb" ]]; then
    provision_deb
  elif [[ "$package_type" == "rpm" ]]; then
    provision_rpm
  fi
}

main
