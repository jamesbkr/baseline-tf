#!/usr/bin/env bash

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SECURITY_TOKEN
unset AWS_SESSION_TOKEN

while getopts "e:u:p:s:t:f:" arg ; do 
	case $arg in 
		p)
			profile=$OPTARG
			;;
		s)
			serial=$OPTARG
			;;
		t)
			token=$OPTARG
			;;
		f)
			file=$OPTARG
			source $file
			;;
	esac
done

( test -n $profile -a -n $serial -a -n $token) || usage

get_temp_credentials

( test -n "$AWS" ) || AWS="aws"

usage() {
	echo "Usage: source $0 -p aws_credentials_profile -s serial -t token"
	echo "OR: source $0 -f parameter_file -t token"
	echo -e "\t -p profile name from ~/.aws/credentials"
	echo -e "\t -s serial number of MFA device, virtual MFA looks like arn:aws:iam::account:mfa/user"
	echo -e "\t -t temporary token from MFA"
	echo -e "\t -f file name to read all parameters from (except token)"
}

function get_temp_credentials() {

	# checking for correct environment
	( test $env == 'dev' -o $env == 'prd' -o $env == 'tst' -o $env == 'stg' ) || usage
	# and if profile is set too
	( test -n $profile ) || ( test -n $AWS_PROFILE ) || usage

	# XORing presense of serial and token, if both are present fine, if only one - exit with usage message
	( test -n "$serial" -o -n "$token" ) && ! ( test -n  "$serial" -a -n "$token" )  &&  usage 

	if [ -n "$token" ] ; then 

		TMP=/tmp/sts-$$.json
		$AWS  --profile ${profile} sts get-session-token --serial-number ${serial}  --token-code ${token} >$TMP

		export AWS_ACCESS_KEY_ID=`jq '.Credentials.AccessKeyId' <$TMP| sed -e 's/"//g'`
		export AWS_SECRET_ACCESS_KEY=`jq '.Credentials.SecretAccessKey' <$TMP| sed -e 's/"//g'`
		export AWS_SECURITY_TOKEN=`jq '.Credentials.SessionToken' <$TMP| sed -e 's/"//g'`

		echo "Using temp credentials"
		echo " token: $AWS_SECURITY_TOKEN"
		echo "key: $AWS_SECRET_ACCESS_KEY"
		echo "key-id: $AWS_ACCESS_KEY_ID"
		rm -f $TMP
	else
		( test -n $AWS_PROFILE ) || AWS_PROFILE=$profile
		echo "using credentials profile: $AWS_PROFILE"
	fi
	echo -e "\n--------------------------------------------------------------------------------\n"
}