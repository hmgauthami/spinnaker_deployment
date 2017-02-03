#!/bin/bash

# Make the build fail on errors.
set -e

ARRAY=(
git
software-properties-common
oracle-java8-installer
oracle-java8-set-default
oracle-java8-unlimited-jce-policy
libjna-java
sbt
apt-transport-https
wget
)
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
  for i in `echo  ${ARRAY[@]}`
  do
  sudo add-apt-repository -y ppa:webupd8team/java && sudo apt-get update && echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections && echo deb https://dl.bintray.com/sbt/debian / | sudo tee -a /etc/apt/sources.list.d/sbt.list && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 && sudo apt-get update
  sudo apt-get install -y $i
  done
  wget -O - -o /dev/null http://get.takipi.com | sudo bash /dev/stdin -i --sk=S17143#LfxEsxQSiDMmHUz9#Gc0TUhkKoQcmEaFvbEu/ATh4a+pJLOM3SCenfM8kVNI=#6914
  sudo apt install -y python.pip
  sudo pip install awscli
  echo $packages
  export AWS_ACCESS_KEY_ID=xxxxxxxxxx
  export AWS_SECRET_ACCESS_KEY=xxxxxxxxxx
  export AWS_DEFAULT_REGION=us-west-2


##Check Package Versions.
## PORTAL



if [[ "$packages" == "modeler-gy-portal=1.0-SNAPSHOT" ]]
  then
  printf "Installing Portal package"
  aws s3 cp s3://m6builds/modeler-gy-portal_1.0-SNAPSHOT_all.deb modeler-gy-portal_1.0-SNAPSHOT_all.deb
  aws s3 cp s3://m6configs/certs . --recursive
  sudo dpkg -i /home/ubuntu/modeler-gy-portal_1.0-SNAPSHOT_all.deb
  sudo mkdir /usr/share/modeler-gy-portal/certs && sudo mv *.pem /usr/share/modeler-gy-portal/certs/
  sudo ./bin/modeler-gy-portal -Dconfig.file=conf/application.conf -Dhttps.keyStore=certs/serverKeyStore.jks -Dhttps.keyStorePassword=COTSpass101
  #touch start-dev
  #echo "sudo ./bin/modeler-gy-portal -Dconfig.file=conf/application.conf" > start-dev
  #cat start-dev
  #sudo mv start-dev /usr/share/modeler-gy-portal/
  #chmod +x /usr/share/modeler-gy-portal/start-dev
  #sudo nohup /usr/share/modeler-gy-portal/start-dev > /dev/null 2>&1 &
  if [ $? -eq 0 ]; then
    echo OK
    netstat -alnp | grep 9000
  else
    echo FAIL
  fi
elif [[ "$packages" == "skymachine-platform*" ]]
then
  printf "Installing Platform Package"
  echo \"deb http://debian.datastax.com/community stable main\" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
  curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add -
  sudo apt-get update && sudo apt-get install -y dsc30 && sudo apt-get install -y cassandra-tools
  aws s3 cp s3://m6builds/skymachine-platform_0.2.0_all.deb /home/ubuntu/
  sudo dpkg -i /home/ubuntu/skymachine-platform_0.2.0_all.deb
else
  printf "exit"
fi

printf "Installed dependiences Version details: "

echo "GIT:"  && git --version
echo " "
echo "JAVA:" && java -version
echo " "
echo "SBT:" && sbt sbt-version
echo " "
echo "TAKIPI:" && ps -ef | grep takipi
echo " "


  # Enforce the package installation order.
  #for package in $packages; do sudo apt-get install --force-yes -y $package; done

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
