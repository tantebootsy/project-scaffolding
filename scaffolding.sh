#! /bin/bash

REMOTE_BASEURL_TEMPLATE=git@github.com:tantebootsy
REMOTE_BASEURL_PROJECT=$REMOTE_BASEURL_TEMPLATE
LOCAL_MYSQL_ADMIN_USERNAME=root
LOCAL_MYSQL_ADMIN_PASSWORD=root

# path (relative to the directory into which the template is cloned to) to database-file to import into local db
LOCAL_MYSQL_FILE_TEMPLATE=storage/db/t3t_7.sql
VERBOSE=true

# wrapper for command-execution
function exec_command {
	eval $1
	if [ $? -ne 0 ]; then
		echo "WARNING! There was a problem with the following command: '$1'. Script terminated."
		exit 1
	else
		if [ -n "$2" ] && [ "$VERBOSE" = true ]; then
			echo "... $2 ($1)."
		fi
	fi	
}

cd $(pwd)

echo "
Enter the name of the folder into which the template shall be cloned, then press [ENTER]:
"

exec_command "read FOLDER"
exec_command "git clone $REMOTE_BASEURL_TEMPLATE/t3-tmpl.git $FOLDER" "template cloned"
exec_command "cd $FOLDER"

# template-remote is renamed as it might be needed to push changes directly to the template-remote later on
exec_command "git remote rename origin tmpl" "template-remote renamed"

echo "
Enter the name of the project's remote-repository to which GIT shall push changes from now on, then press [ENTER]:
WARNING! This will DELETE all content of the remote-repository including its history!
"
exec_command "read REPOSITORY"
exec_command "git remote add origin $REMOTE_BASEURL_PROJECT/$REPOSITORY" "new project remote-repository added"
exec_command "git push origin --mirror" "content of template-repository pushed to newly added project remote-repository"

for BRANCH in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
	exec_command "git branch $BRANCH -u origin/$BRANCH" "locally existing branches of 'origin' adjusted to use newly added remote-repository"
done

echo "Enter the name of the local project-database to be created, then press [ENTER]:"

exec_command "read DATABASE"

# as no charset and collation is specified the following needs proper server-settings for character-set and collation
exec_command "mysql -u$LOCAL_MYSQL_ADMIN_USERNAME -p$LOCAL_MYSQL_ADMIN_PASSWORD -e \"CREATE DATABASE $DATABASE\"" "project-database created"

exec_command "mysql -u$LOCAL_MYSQL_ADMIN_USERNAME -p$LOCAL_MYSQL_ADMIN_PASSWORD -v $DATABASE < $LOCAL_MYSQL_FILE_TEMPLATE" "template-sql-file imported into newly created project-database"