#! /bin/bash

# Base url of the repository the template is fetched from
REMOTE_TEMPLATE_BASEURL=git@github.com:tantebootsy

# Name of the repository the template is fetched from
REMOTE_TEMPLATE_NAME=t3-tmpl.git

# Base url of the repository the template-files are mirrored to
REMOTE_PROJECT_BASEURL=$REMOTE_TEMPLATE_BASEURL

# Command with which MySQL is executable via the command-line
LOCAL_MYSQL_COMMAND=mysql

# MySQL admin username of local database
LOCAL_MYSQL_ADMIN_USERNAME=root

# MySQL admin password of local database
LOCAL_MYSQL_ADMIN_PASSWORD=root

# Path to database-file which shall be imported into the local databse. The path can either be absolute or relative. If it's relative the database-file has to be present in the template-repository already. So e.g. the template is cloned into the folder "testing" and the database file then is under "testing/storage/database.sql" the variable has to be set as follows: "LOCAL_MYSQL_TEMPLATE_FILE=storage/database.sql"
LOCAL_MYSQL_TEMPLATE_FILE=storage/db/t3t_7.sql

# Defines whether processing-information is shown
VERBOSE=true

# Defines whether script-explanation and instructions are shown
README=true

# wrapper for command-execution
function exec_command {
	eval $1
	if [ $? -ne 0 ]; then
		echo "WARNING! There was a problem with the following command: '$1'. Script terminated."
		exit 1
	else
		if [ -n "$2" ] && [ "$VERBOSE" = true ]; then
			echo "... $2 (command used: '$1')."
		fi
	fi	
}

if [ "$README" = true ]; then
	echo "
This script clones an existing template-repository and then mirrors all branches of this repository to another existing project remote-repository. WARNING! It will DELETE all content of the project's remote-repository including its history! 
Furthermore it locally creates a database and imports a template SQL-file into this database.

INSTRUCTIONS:
1. Be sure to have a remote-repository for your project created.
2. Adjust the variables of this script within the source-code to fit your needs.
3. Start your MySQL-server and be sure to have proper settings for character-set and collation for new databases set. E.g. in 'my.cnf' set
   [mysqld]
   character-set-server=utf8
   collation-server=utf8_general_ci
4. Start GIT if it's not running already.
"

	read -p "Did you just change some of this script's variables? Then type 'y' or 'Y' to restart it. Press any other key to simply continue." -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		exec "$0"
	fi
fi

echo "
Enter the path (absolute or relative to the current directory) into which the template shall be cloned. If the directory exists already remember it has to be empty. Then press [ENTER]:
"

exec_command "read LOCAL_PROJECT_FOLDER"
exec_command "git clone $REMOTE_TEMPLATE_BASEURL/$REMOTE_TEMPLATE_NAME $LOCAL_PROJECT_FOLDER" "template cloned"
exec_command "cd $LOCAL_PROJECT_FOLDER"

# template-remote is renamed as it might be needed to push changes directly to the template-remote later on
exec_command "git remote rename origin tmpl" "template-remote renamed"

echo "
Enter the name of the project's remote-repository to which the template's content shall get mirrored to and to which GIT shall push changes from now on by default. Then press [ENTER]. WARNING! This will OVERWRITE all content of the project's remote-repository with the content from the template-repository – including its history!
"
exec_command "read REMOTE_PROJECT_NAME"
exec_command "git remote add origin $REMOTE_PROJECT_BASEURL/$REMOTE_PROJECT_NAME" "new project remote-repository added"
exec_command "git push origin --mirror" "mirrored content of template-repository to newly added project remote-repository"

for BRANCH in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
	exec_command "git branch $BRANCH -u origin/$BRANCH" "local branch '$BRANCH' adjusted to use the remote-repository of the newly added remote-repository by default"
done

echo "Enter the name of the local project-database to be created, then press [ENTER]:"

exec_command "read LOCAL_MYSQL_PROJECT_DATABASE"

# as no charset and collation is specified the following needs proper server-settings for character-set and collation
exec_command "$LOCAL_MYSQL_COMMAND -u$LOCAL_MYSQL_ADMIN_USERNAME -p$LOCAL_MYSQL_ADMIN_PASSWORD -e \"CREATE DATABASE $LOCAL_MYSQL_PROJECT_DATABASE\"" "project-database created"

exec_command "$LOCAL_MYSQL_COMMAND -u$LOCAL_MYSQL_ADMIN_USERNAME -p$LOCAL_MYSQL_ADMIN_PASSWORD -v $LOCAL_MYSQL_PROJECT_DATABASE < $LOCAL_MYSQL_TEMPLATE_FILE" "sql-file imported into newly created project-database"