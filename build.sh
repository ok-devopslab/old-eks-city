#! /bin/bash

action=$1
env=$2

if [ $env == "prod" ]; then
  AWS_REGION="us-east-2"
elif [ $env == "prod-dr" ]; then
  AWS_REGION="us-west-2"
else
  AWS_REGION="us-east-2"
fi

echo "$AWS_REGION"
accountid=$(aws sts get-caller-identity --query Account --output text)

dynamodb_table=terraform-backend-$env-lock
created_dynamodb_table=$(aws dynamodb list-tables | jq .TableNames[] | tr -d '"' | grep -w "$dynamodb_table")

bucket=ccb-cua-$env-terraform-$accountid
created_bucket=$(aws s3 ls | grep -w "$bucket" | awk '{print $3}')

if [ "$created_bucket" != "$bucket" ]; then
  aws s3 mb s3://"$bucket" --region "$AWS_REGION"
  aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled
fi

if [ "$created_dynamodb_table" != "$dynamodb_table" ]; then
  aws dynamodb create-table --region "$AWS_REGION" --table-name "$dynamodb_table" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 > /dev/null 2>&1
fi

if [ "$3" == "" ]; then
  service_apply="vpc s3 rds gaurdduty secretmanager eks eks-services"
else
  service_apply="$3"
fi

if [ "$action" = "plan" ]; then
  for service in $service_apply ; do
    echo "
    ###########################################################
    #                  Planning ""$service""                 #
    ###########################################################"
    echo ""
    cd "$service" || exit
    rm -rf .terraform*
    terraform init -backend-config="bucket=$bucket" -backend-config="dynamodb_table=$dynamodb_table" -backend-config="key=$service/$service-state.tfstate" -backend-config="encrypt=true" -backend-config="region=$AWS_REGION" > /dev/null 2>&1
    terraform "$action" -var environment="$env" -var remote_state_bucket="$bucket" -var remote_state_region="$AWS_REGION" -var aws_region="$AWS_REGION"
    sleep 1
    rm -rf .terraform*
    cd ..
  done
fi

if [ "$action" = "apply" ]; then
  for service in $service_apply ; do
    echo "
    ###########################################################
    #                  Deploying ""$service""                 #
    ###########################################################"
    echo ""
    cd "$service" || exit
    rm -rf .terraform*
    terraform init -backend-config="bucket=$bucket" -backend-config="dynamodb_table=$dynamodb_table" -backend-config="key=$service/$service-state.tfstate" -backend-config="encrypt=true" -backend-config="region=$AWS_REGION" > /dev/null 2>&1
    terraform "$action" -var environment="$env" -var remote_state_bucket="$bucket" -var remote_state_region="$AWS_REGION" -var aws_region="$AWS_REGION" --auto-approve
    if [ $? -eq 0 ];then
      echo ""
      echo "$service Deployed Successfully ...."
      echo ""
    else
      echo ""
      echo "Retrying with $service .... "
      echo ""
      terraform init -backend-config="bucket=$bucket" -backend-config="dynamodb_table=$dynamodb_table" -backend-config="key=$service/$service-state.tfstate" -backend-config="encrypt=true" -backend-config="region=$AWS_REGION" > /dev/null 2>&1
      terraform "$action" -var environment="$env" -var aws_region="$AWS_REGION" -var remote_state_bucket="$bucket" -var remote_state_region="$AWS_REGION" -var aws_region="$AWS_REGION" --auto-approve
      echo ""
      echo "$service Deployed Successfully ...."
    fi
    sleep 1
    rm -rf .terraform*
    cd ..
  done
fi

service_destroy=$(echo "$service_apply" | awk '{do printf "%s"(NF>1?FS:RS),$NF;while(--NF)}')

if [ "$action" = "destroy" ]; then
  for service in $service_destroy ; do
    echo "
    ############################################################
    #                   Destroying ""$service""                #
    ############################################################"
    echo ""
    cd "$service" || exit
    rm -rf .terraform*
    terraform init -backend-config="bucket=$bucket" -backend-config="dynamodb_table=$dynamodb_table" -backend-config="key=$service/$service-state.tfstate" -backend-config="encrypt=true" -backend-config="region=$AWS_REGION" > /dev/null 2>&1
    terraform "$action" -var environment="$env" -var remote_state_bucket="$bucket" -var remote_state_region="$AWS_REGION" -var aws_region="$AWS_REGION" --auto-approve
    if [ $? -eq 0 ];then
      echo ""
      echo "$service Destroyed Successfully ...."
      echo ""
    else
      echo ""
      echo "Retrying with $service .... "
      echo ""
      terraform init -backend-config="bucket=$bucket" -backend-config="dynamodb_table=$dynamodb_table" -backend-config="key=$service/$service-state.tfstate" -backend-config="encrypt=true" -backend-config="region=$AWS_REGION" > /dev/null 2>&1
      terraform "$action" -var environment="$env" -var aws_region="$AWS_REGION" -var remote_state_bucket="$bucket" -var remote_state_region="$AWS_REGION" -var aws_region="$AWS_REGION" --auto-approve
      echo ""
      echo "$service Destroyed Successfully ...."
    fi
    sleep 1
    rm -rf .terraform*
    cd ..
  done
  vpc=$(aws ec2 describe-vpcs | jq .Vpcs[].Tags | grep -v "null" | jq .[].Value | tr -d '"' | grep "$env")
  if [ "$vpc" != "" ]; then
    echo "VPC not deleted yet !!!!!"
  else
    sleep 10
  fi
fi
