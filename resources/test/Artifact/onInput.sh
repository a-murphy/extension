#!/bin/bash -e

check_artifact_properties() {
  local resourceName="$1"
  local intMasterName=$(eval echo "$"res_"$resourceName"_int_masterName)
  local repositoryPath=$(find_resource_variable $resourceName repositoryPath)
  local artifactName=$(find_resource_variable $resourceName artifactName)
  
  echo "$resourceName"
  echo "$intMasterName"
  echo "$repositoryPath"
  echo "$artifactName"
  
  printenv

  if [ "$intMasterName" != "artifactory" ]; then
    echo "Error: Integration type not supported for this resource type."
    echo "Error: An Artifactory integration should be provided in sourceArtifactory."
    return 1
  fi

  if [ -z "$repositoryPath" ]; then
    echo "Error: Missing repositoryPath"
    return 1
  fi

  if [ -z "$artifactName" ]; then
    echo "Error: Missing artifactName"
    return 1
  fi
}

download_artifact() {
  local resourceName="$1"
  local resourcePath=$(find_resource_variable $resourceName resourcePath)

  execute_command "check_artifact_properties $resourceName"

  local rtUrl=$(eval echo "$"res_"$resourceName"_sourceArtifactory_url)
  local rtUser=$(eval echo "$"res_"$resourceName"_sourceArtifactory_user)
  local rtApiKey=$(eval echo "$"res_"$resourceName"_sourceArtifactory_apikey)

  execute_command "retry_command \$jfrog_cli_path rt config --insecure-tls=$no_verify_ssl --url $rtUrl --user $rtUser --apikey $rtApiKey --interactive=false"

  local repositoryPath=$(find_resource_variable $resourceName repositoryPath)
  local artifactName=$(find_resource_variable $resourceName artifactName)

  execute_command "pushd \"$resourcePath\""
  execute_command "retry_command \$jfrog_cli_path rt download --fail-no-op --insecure-tls=$no_verify_ssl \"${repositoryPath}/${artifactName}\""
  execute_command "popd"
}

download_artifact "%%context.resourceName%%"
