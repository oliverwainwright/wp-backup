#!/bin/bash
#
# Date: 2019-07-14
# Environment: KnownHost VPS
# Author: oliverwainwright.com
# Description: Backup Wordpress files and database to Amazon S3 Buckets
# Prerequisites: AWS CLI tool, AWS Account, AWS S3 Bucket, AWS IAM Policy & Role for
# account to access your S3 Bucket and nothing else
# RUN AS ROOT so you don't have to use a db password in your script for mysqldump

# Your S3 bucket name
# Replace "YOUR_BUCKET" with your actual S3 Bucket Name
S3_BUCKET="s3://YOUR_BUCKET"

# Loop thru home dirs for accounts running wordpress
for dir in `ls -d /home/*`
do
	WP_DIR=$dir
	WP_BASENAME="${WP_DIR##*/}"

	# if wp-config.php exists, then it's a wordpress site
	if [ -f $dir/www/wp-config.php ]
	then
		echo "##### $WP_BASENAME is a wp site #####"

		# setup backup directory
		BACKUP_DIR=$dir/backup

		[ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR

		# parse wp-config.php to get DB_USER, DB_NAME, DB_PASSWORD
		DB_USER=`cat $dir/www/wp-config.php | grep DB_USER | awk '{ print $3 }'`
		DB_NAME=`cat $dir/www/wp-config.php | grep DB_NAME | awk '{ print $3 }'`

		# prior to knownhost, I used hostgator
		# hostgator wp-config.php was formatted differently, less whitespace
		if [ -z $DB_USER ]
		then
			DB_USER=`cat $dir/www/wp-config.php | grep DB_USER | awk '{ print $2 }' | sed s/\\)\\;//`
		fi			

		# prior to knownhost, I used hostgator
		# hostgator wp-config.php was formatted differently, less whitespace
		if [ -z $DB_NAME ]
		then
			DB_NAME=`cat $dir/www/wp-config.php | grep DB_NAME | awk '{ print $2 }' | sed s/\\)\\;//`
		fi			

		DB_NAME=${DB_NAME//\'/}

		# use mysqldump to backup wordpress databases and compress backup file
		mysqldump $DB_NAME > $BACKUP_DIR/`date +%Y%m%d%H%M`-$DB_NAME-backup.sql
		gzip -9f $BACKUP_DIR/`date +%Y%m%d%H%M`-$DB_NAME-backup.sql
		
		# cleanup old database backups, keep 7 days locally 
		find $BACKUP_DIR -type f -name "*-$DB_NAME-backup.sql.gz" -atime +6 -exec rm -f {} \;

		# use aws sync to copy files from VPS to S3 Bucket
		/usr/local/bin/aws s3 sync $BACKUP_DIR $S3_BUCKET/$WP_BASENAME/backup/
		/usr/local/bin/aws s3 sync $dir/www $S3_BUCKET/$WP_BASENAME/www/

	fi
done
