#! /bin/bash

#http://stackoverflow.com/questions/3846380/how-to-iterate-through-all-git-branches-using-bash-script

# wrapper for command-execution
function exec_command {
	eval $1
	if [ $? -ne 0 ]; then
		echo "WARNING! There was a problem with the following command: '$1'. Script will be terminated."
		exit 1
	else
		echo "... '$1' done"
	fi	
}

# clone template
exec_command "git clone --bare git@github.com:tantebootsy/t3-tmpl.git testing"

exec_command "cd testing"

# bisheriges tmpl-remote umbenennen, wird ggf. später für Änderungen an der Template-Vorlage benötigt
exec_command "git remote rename origin tmpl"

# neues projekt-remote hinzufügen
echo "
Enter the URL to the project-repo to which GIT shall push changes from now on, then press [ENTER]:
WARNING! This will delete the content of the project-repo including its history!
"
exec_command "read url"

exec_command "git remote add origin $url"

# push content of template-repo to newly added remote-repo
exec_command "git push origin --mirror"

for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
	git branch $branch -u origin/$branch
done

# name for project-database is asked for
echo "Enter the name of the database for the project to be created, then press [ENTER]:"

exec_command "read db"

# project-database is created (needs proper character-set and collation-settings set vi my.cnf)
exec_command "mysql -uroot -proot -e \"CREATE DATABASE $db\""