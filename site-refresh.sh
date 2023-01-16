#!/bin/bash
while getopts r:f:n:k: flag
do
  case "${flag}" in
    r) repo=${OPTARG};;
    f) folder=${OPTARG};;
    n) name=${OPTARG};;
    k) key=${OPTARG};;
  esac
done
path=""
IFS="/" read -r -a parts <<< "$folder"
for index in "${!parts[@]}"
do
  if [ "${parts[index]}" != "" ]; 
  then
    path+="/${parts[index]}"
    if [ ! -d "${path}" ]
    then
      mkdir "${path}"
    fi
  fi
done
if  [ ! -f "${folder}/ver.txt" ]
then 
  echo "Cloning repo: ${repo}"
  git clone "${repo}" "${folder}" > /dev/null 2>&1
  cd "${folder}"
  git branch -vv > ver.txt
else
  echo "Pulling repo: ${folder}"
  cd "${folder}"
  git pull --ff-only > /dev/null 2>&1
  if [ -f "${folder}/ver.txt" ]
  then
    rm -f "${folder}/ver.txt"
  fi
  git branch -vv > ver.txt
fi
deployed=0
if [ ! -f "/var/www/html/ver.txt" ]
then
  echo "Deploying site: ${name}"
  /bin/rm -rf /var/www/html/*
  /bin/cp -rf ${folder}/* /var/www/html
  deployed=1
else
  if ! cmp -s /var/www/html/ver.txt    "${folder}/ver.txt"
  then
    echo "Redeploying site: ${name}"
    /bin/rm -rf /var/www/html/*
    /bin/cp -rf ${folder}/* /var/www/html
    deployed=1
  else
    echo "Site up-to-date: ${name}"
  fi
fi
if [ "${deployed}" -eq "1" ]
then
  /bin/curl -X POST -H "Content-Type: application/json" -d '{"value1":"'"${name}"'","value2":"Success"}' "https://maker.ifttt.com/trigger/deployment/with/key/${key}" > /dev/null 2>&1
fi