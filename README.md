I have some websites hosted ona a VPS with Known Host.
I needed a way to backup all the website databases and files to remote location.
So, I decided to use Amazon AWS S3 to store my data securely as follows:

1. Create your AWS S3 bucket with: 
	a. no public access 
	b. enable versioning
	c. AES-256 encryption  
	d. create Lifecycle rule appropriate for your environment

2. Lock down the user that will access your AWS S3 bucket 

3. Create an IAM Policy and attach it to an IAM Group 

IAM Policy wp-db-backup-policy

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::YOUR-BUCKET",
                "arn:aws:s3:::YOUR-BUCKET/*"
            ]
        }
    ]
}

3. Create IAM Group wp-db-backup-group 

4. Attach IAM Policy wp-db-backup-policy to the IAM Group wp-db-backup-group

5. Finally create a new IAM User wp-db-backup-user with 
	a. membership in the wp-db-backup-group
	b. programmatic access only, 
	c. no Interactive Console or API access

6. Download your credentials.csv and save them. You will need the Secret keys to setup your aws-cli access

7. Login to your VPS, download and install the aws-cli for your OS. I am using Linux.
	a. Configure aws-cli, aws configure
	b. Test aws-cli aws s3 ls s3
	c. Copy wp-backup.sh from github to /usr/local/bin/wp-backup.sh
	d. Make sure the script is executable
	e. Add your S3 Bucket Name to the script and test

